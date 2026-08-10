#!/usr/bin/env node
import { createServer } from "node:http";
import { createReadStream } from "node:fs";
import { stat } from "node:fs/promises";
import path from "node:path";
import { Readable } from "node:stream";
import { pipeline } from "node:stream/promises";
import { fileURLToPath } from "node:url";
import worker from "../worker/index.mjs";

const projectDir=path.resolve(path.dirname(fileURLToPath(import.meta.url)),"..");
const clientDir=path.join(projectDir,"dist","client");
const port=Number(process.env.PORT||process.argv[2]||4177);
const host=process.env.HOST||(process.env.PORT?"0.0.0.0":"127.0.0.1");
const contentTypes={
  ".css":"text/css; charset=utf-8",".html":"text/html; charset=utf-8",
  ".js":"text/javascript; charset=utf-8",".json":"application/json; charset=utf-8",
  ".jpg":"image/jpeg",".jpeg":"image/jpeg",".png":"image/png",".svg":"image/svg+xml",
  ".woff":"font/woff",".woff2":"font/woff2",".mp4":"video/mp4",".pdf":"application/pdf"
};

function safeFile(pathname){
  const decoded=decodeURIComponent(pathname);
  const candidate=path.resolve(clientDir,`.${decoded}`);
  return candidate===clientDir||candidate.startsWith(`${clientDir}${path.sep}`)?candidate:null;
}

// Bundled demo assets carry a base62 content hash in the filename (Vite's
// `name-DoaGtyQD.js` shape), so their bytes never change under a given URL.
const hashedAssetPath=/^\/tools\/[^/]+\/demo\/assets\/(?:[^/]+\/)*[^/]*-[A-Za-z0-9_-]{8}\.[^/]+$/;

function cacheControl(pathname){
  if(hashedAssetPath.test(pathname))return "public, max-age=31536000, immutable";
  if(pathname.startsWith("/assets/")||pathname.startsWith("/tools/"))return "public, max-age=86400, stale-while-revalidate=604800";
  return "public, max-age=300, stale-while-revalidate=3600";
}

// Returns {start,end} for a satisfiable single range, false when the range is
// syntactically valid but unsatisfiable (416), and null when the header should
// be ignored entirely and the full representation served (RFC 7233 §3.1).
function parseRange(value,size){
  if(!value)return null;
  const trimmed=value.trim();
  if(!/^bytes=/i.test(trimmed))return null;
  const specs=trimmed.slice(trimmed.indexOf("=")+1).split(",");
  const parsed=[];
  for(const spec of specs){
    const match=/^(\d*)-(\d*)$/.exec(spec.trim());
    if(!match||(match[1]===""&&match[2]===""))return null;
    if(match[1]===""){
      const suffix=Number(match[2]);
      if(!Number.isSafeInteger(suffix))return null;
      parsed.push(suffix===0||size===0?false:{start:Math.max(size-suffix,0),end:size-1});
      continue;
    }
    const start=Number(match[1]);
    const end=match[2]===""?size-1:Number(match[2]);
    if(!Number.isSafeInteger(start)||!Number.isSafeInteger(end))return null;
    if(match[2]!==""&&end<start)return null;
    parsed.push(start>=size?false:{start,end:Math.min(end,size-1)});
  }
  return parsed.length===1?parsed[0]:null;
}

function matchesEtag(headerValue,etag){
  if(!headerValue)return false;
  const weakEtag=etag.replace(/^W\//,"");
  return headerValue.split(",").some(candidate=>{
    const value=candidate.trim();
    return value==="*"||value.replace(/^W\//,"")===weakEtag;
  });
}

// If-Range accepts only a strong validator: an exact last-modified date or a
// non-weak entity-tag. Anything else serves the full representation instead.
function ifRangeAllows(headerValue,etag,mtimeMs){
  if(!headerValue)return true;
  const value=headerValue.trim();
  if(/^(W\/)?"/.test(value))return !value.startsWith("W/")&&value===etag;
  const parsed=Date.parse(value);
  return Number.isFinite(parsed)&&parsed===Math.trunc(mtimeMs/1000)*1000;
}

function fileBody(file,start,end){
  return Readable.toWeb(createReadStream(file,start===undefined?undefined:{start,end}));
}

const env={ASSETS:{async fetch(request){
  const url=new URL(request.url),file=safeFile(url.pathname);
  if(!file)return new Response("Bad path",{status:400});
  try{
    const info=await stat(file);
    if(!info.isFile())return new Response("Not found",{status:404});
    const etag=`"${info.size.toString(16)}-${Math.trunc(info.mtimeMs).toString(16)}"`;
    const headers={
      "accept-ranges":"bytes",
      "cache-control":cacheControl(url.pathname),
      "content-type":contentTypes[path.extname(file).toLowerCase()]||"application/octet-stream",
      "etag":etag,
      "last-modified":info.mtime.toUTCString()
    };
    const ifNoneMatch=request.headers.get("if-none-match");
    const ifModifiedSince=request.headers.get("if-modified-since");
    if(matchesEtag(ifNoneMatch,etag)||(!ifNoneMatch&&ifModifiedSince&&Date.parse(ifModifiedSince)>=Math.trunc(info.mtimeMs/1000)*1000)){
      return new Response(null,{status:304,headers});
    }
    const rangeAllowed=ifRangeAllows(request.headers.get("if-range"),etag,info.mtimeMs);
    const range=request.method==="GET"&&rangeAllowed?parseRange(request.headers.get("range"),info.size):null;
    if(range===false){
      headers["content-range"]=`bytes */${info.size}`;
      return new Response(null,{status:416,headers});
    }
    if(range){
      headers["content-length"]=String(range.end-range.start+1);
      headers["content-range"]=`bytes ${range.start}-${range.end}/${info.size}`;
      return new Response(fileBody(file,range.start,range.end),{status:206,headers});
    }
    headers["content-length"]=String(info.size);
    if(request.method==="HEAD")return new Response(null,{status:200,headers});
    return new Response(fileBody(file),{status:200,headers});
  }catch(error){
    if(error&&error.code==="ENOENT")return new Response("Not found",{status:404});
    throw error;
  }
}}};

// A client that resets the connection is routine, not a server fault, so it must
// not be logged or answered with a second response.
const disconnectCodes=new Set(["ECONNRESET","EPIPE","ERR_STREAM_DESTROYED","ERR_STREAM_PREMATURE_CLOSE"]);

const server=createServer(async(req,res)=>{
  try{
    const forwardedProto=String(req.headers["x-forwarded-proto"]||"").split(",",1)[0].trim().toLowerCase();
    const protocol=forwardedProto==="https"||forwardedProto==="http"?forwardedProto:"http";
    const origin=`${protocol}://${req.headers.host||`127.0.0.1:${port}`}`;
    const request=new Request(new URL(req.url||"/",origin),{method:req.method,headers:req.headers});
    const response=await worker.fetch(request,env);
    // The client can disconnect while the worker is still resolving the asset,
    // so the body has to be released explicitly on that path.
    if(res.destroyed){await response.body?.cancel().catch(()=>{});return}
    res.writeHead(response.status,Object.fromEntries(response.headers));
    if(req.method==="HEAD"||!response.body){res.end();return}
    // pipeline applies backpressure and tears the file stream down on a
    // premature close, whichever side ends first.
    await pipeline(Readable.fromWeb(response.body),res);
  }catch(error){
    if(disconnectCodes.has(error?.code))return;
    process.stderr.write(`${req.method} ${req.url} failed: ${error&&error.stack||error}\n`);
    if(res.headersSent){res.destroy();return}
    res.writeHead(500,{"content-type":"text/plain; charset=utf-8"});
    res.end(String(error&&error.stack||error));
  }
});

server.listen(port,host,()=>process.stdout.write(`Portfolio server: http://${host}:${port}/\n`));
for(const signal of ["SIGINT","SIGTERM"]){process.on(signal,()=>server.close(()=>process.exit(0)))}
