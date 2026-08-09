#!/usr/bin/env node
import { createServer } from "node:http";
import { readFile, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import worker from "../worker/index.mjs";

const projectDir=path.resolve(path.dirname(fileURLToPath(import.meta.url)),"..");
const clientDir=path.join(projectDir,"dist","client");
const port=Number(process.env.PORT||process.argv[2]||4177);
const host=process.env.HOST||"127.0.0.1";
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

const env={ASSETS:{async fetch(request){
  const url=new URL(request.url),file=safeFile(url.pathname);
  if(!file)return new Response("Bad path",{status:400});
  try{
    const info=await stat(file);
    if(!info.isFile())return new Response("Not found",{status:404});
    const headers={"content-type":contentTypes[path.extname(file).toLowerCase()]||"application/octet-stream","content-length":String(info.size)};
    if(request.method==="HEAD")return new Response(null,{status:200,headers});
    return new Response(await readFile(file),{status:200,headers});
  }catch(error){
    if(error&&error.code==="ENOENT")return new Response("Not found",{status:404});
    throw error;
  }
}}};

const server=createServer(async(req,res)=>{
  try{
    const origin=`http://${req.headers.host||`127.0.0.1:${port}`}`;
    const request=new Request(new URL(req.url||"/",origin),{method:req.method,headers:req.headers});
    const response=await worker.fetch(request,env);
    res.writeHead(response.status,Object.fromEntries(response.headers));
    if(req.method==="HEAD"||!response.body){res.end();return}
    const reader=response.body.getReader();
    for(;;){const {done,value}=await reader.read();if(done)break;res.write(value)}
    res.end();
  }catch(error){res.writeHead(500,{"content-type":"text/plain; charset=utf-8"});res.end(String(error&&error.stack||error))}
});

server.listen(port,host,()=>process.stdout.write(`Portfolio server: http://${host}:${port}/\n`));
for(const signal of ["SIGINT","SIGTERM"]){process.on(signal,()=>server.close(()=>process.exit(0)))}
