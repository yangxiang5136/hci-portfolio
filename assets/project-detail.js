(function(){
  "use strict";
  const projects={
    "/projects/digital-me/":{
      accent:"#2f6fed",soft:"#eaf1ff",kind:["代表项目","Featured project"],status:["长期个人系统","Long-running personal system"],
      title:["Digital Me · 个人 AI 元认知系统","Digital Me · Personal AI Metacognition System"],
      deck:["把消息、任务、资料与长期记忆连接成一个由人做最终决定的个人智能系统。","A human-gated personal intelligence system connecting messages, tasks, documents, and long-term memory."],
      section:["不是替我跳到答案，而是帮我找到下一步","Not a shortcut to the answer, but a way to find the next step"],
      body:["系统把可追溯的观察、建议和行动入口放到同一条工作流中，同时保留来源、边界和回退路径。","The system places traceable observations, suggestions, and action entry points in one workflow while preserving provenance, boundaries, and rollback paths."],
      role:["产品与体验架构、个人研究和持续使用；实现包含 AI 辅助。公开图片使用合成演示数据，不公开私人消息。","Product and experience architecture, personal inquiry, and ongoing use; implementation included AI assistance. Public visuals use synthetic demo data and expose no private messages."],
      points:[["以证据与来源支撑建议，而不是隐藏推断。","Ground suggestions in evidence and provenance instead of hiding inference."],["关键行动始终保留人的确认与回退。","Keep human confirmation and rollback around consequential actions."],["把失败、未知和隐私边界作为界面的一部分。","Treat failure, uncertainty, and privacy boundaries as interface elements."]],
      media:[["/assets/digital-me-public-overview.jpg","系统公开概览","Public system overview"],["/assets/digital-me-public-structure.jpg","能力与边界结构","Capability and boundary structure"],["/assets/attention-board-synthetic.png","使用合成数据的 Attention Board","Attention Board with synthetic data"]],
      links:[{href:"https://digital-me-dashboard.vercel.app/",zh:"访问公开网站 ↗",en:"Visit public website ↗",primary:true},{href:"https://github.com/yangxiang5136/digital-me-dashboard",zh:"GitHub ↗",en:"GitHub ↗"}]
    },
    "/projects/community-hub/":{
      accent:"#0b7a53",soft:"#e8f6ef",kind:["代表项目","Featured project"],status:["公开产品","Public product"],
      title:["本地华人生活服务社区站","Local Chinese Community Hub"],
      deck:["在不过度增加账户负担的前提下，为本地社区建立足够的身份连续性、信任和联系方式交换。","Building enough identity continuity, trust, and contact exchange for a local community without a heavy account system."],
      section:["把本地生活信息变成可行动的社区关系","Turning local information into actionable community ties"],
      body:["项目围绕二手交易、室友、社区信息与联系方式交换，探索轻量身份系统如何支撑真实的本地协作。","The project connects resale, roommates, local information, and contact exchange to explore how lightweight identity can support real community coordination."],
      role:["产品与体验主导；实现包含 AI 辅助。首页视觉依据真实页面重新排版并脱敏，后续功能图来自公开站点。","Product and experience lead; implementation included AI assistance. The homepage visual is a privacy-safe re-layout grounded in the real interface, followed by captures from the public product."],
      points:[["先解决社区任务，再逐步建立身份连续性。","Start with community tasks, then build identity continuity gradually."],["让联系方式交换发生在足够信任之后。","Move contact exchange behind sufficient trust."],["保持发布与浏览流程在手机上足够轻。","Keep posting and browsing lightweight on mobile."]],
      media:[["/assets/blacksburg-home-portfolio.png","脱敏重制的首页","Privacy-safe homepage reconstruction"],["/assets/blacksburg-publish-mobile.png","移动端发布流程","Mobile publishing flow"],["/assets/blacksburg-roommates-mobile.png","室友信息页面","Roommate listings"]],
      links:[{href:"https://blacksburg-secondhand-production.up.railway.app/",zh:"访问线上产品 ↗",en:"Visit live product ↗",primary:true},{href:"https://github.com/xiangyangvt/blacksburg-secondhand",zh:"GitHub ↗",en:"GitHub ↗"}]
    },
    "/projects/vibrotactile-platform/":{
      accent:"#ef6c35",soft:"#fff0e8",kind:["代表项目","Featured project"],status:["博士研究平台","Doctoral research platform"],
      title:["可穿戴触觉预警测试平台","Vibrotactile Warning Testing Platform"],
      deck:["探索视觉或听觉负荷很高时，有限的触觉通道如何清楚表达方向与紧迫度。","Exploring how a limited tactile channel can communicate direction and urgency under visual or auditory load."],
      section:["给皮肤设计一套可以测量的警示语言","Designing a measurable warning language for the skin"],
      body:["平台连接触觉阵列、实时控制、姿态记录与实验流程，把感知阈值、反应延迟和辨识准确率转化为可重复测试的问题。","The platform connects tactile arrays, real-time control, pose tracking, and study flow to turn perception thresholds, response latency, and identification accuracy into repeatable questions."],
      role:["研究设计与 Python 实验系统构建。公开界面基于真实运行进行高清重绘，参与者与 session 标识均替换为演示值。","Research design and Python experiment-system development. Public interfaces are HD reconstructions grounded in real runs, with participant and session identifiers replaced by demo values."],
      points:[["把方向与紧迫度编码成可比较的触觉信号。","Encode direction and urgency as comparable tactile signals."],["针对个体差异校准刺激强度。","Calibrate stimulus intensity for individual differences."],["把硬件、实验控制和记录整合进同一平台。","Integrate hardware, experimental control, and logging in one platform."]],
      media:[["/assets/vibrotactile-controller-redraw-4k.png","Python 触觉实验控制器","Python haptic study controller"],["/assets/vibrotactile-imu-redraw-hd.png","IMU 实时姿态视图","Real-time IMU pose view"],["/assets/smart-vest-haptic-array.png","躯干触觉阵列","Torso haptic array"]]
    },
    "/projects/workzone-safety/":{
      accent:"#b54708",soft:"#fff4e5",kind:["代表项目","Featured project"],status:["匿名产业合作","Anonymized industry collaboration"],
      title:["智慧工区 SaaS 安全平台","Smart Work-Zone Safety SaaS Platform"],
      deck:["把工人端情境输入、实时定位与管理端工区划定、风险可视化和事件复盘连接成一条双角色流程。","Connecting worker context and location with manager-side work-zone definition, risk visualization, and incident review."],
      section:["从单点报警走向可理解的安全工作流","From isolated alerts to an understandable safety workflow"],
      body:["平台把现场信息、区域规则和管理决策组织成连续流程，让工人与安全经理在报警之前、期间和之后看到不同但一致的行动依据。","The platform organizes field context, zone rules, and management decisions into a continuous flow so workers and safety managers see distinct but consistent action cues before, during, and after an alert."],
      role:["产品经理兼交互设计负责人；主导需求定义、交互模型、利益相关者协调与 MVP 规划，工程实现由团队协作完成。","Product Manager and Interaction Design Lead; led requirements, interaction model, stakeholder coordination, and MVP planning while engineering was delivered collaboratively."],
      points:[["让报警包含原因、位置和下一步。","Give every alert a reason, location, and next step."],["连接工人端输入与管理端风险判断。","Connect worker input with manager-side risk judgment."],["保留事件复盘所需的上下文。","Preserve the context needed for incident review."]],
      media:[["/assets/workzone-manager-home.png","安全经理首页","Safety manager home"],["/assets/workzone-worker-context.png","工人作业情境输入","Worker context input"],["/assets/workzone-manager-dashboard.png","风险管理看板","Risk management dashboard"]]
    },
    "/tools/household-care/":{
      accent:"#7f56d9",soft:"#f2edff",kind:["工具项目","Tool project"],status:["可交互 Demo","Interactive demo"],
      title:["家庭任务与照料协作微型平台","Household Tasks & Care Coordination Micro-Platform"],
      deck:["把今天谁需要做什么、谁正在负责、什么已经完成，放进一个安静的家庭共用界面。","A calm shared view of what needs attention today, who is responsible, and what has already been completed."],
      section:["用低提醒密度维持责任连续性","Maintaining responsibility with low notification density"],
      body:["界面优先呈现异常和需要接手的事项，同时减少重复提醒，让家庭成员快速理解现在的照料状态。","The interface prioritizes exceptions and handoff needs while reducing repetitive reminders, helping household members understand the current care state quickly."],
      role:["界面强调异常优先、低提醒密度和责任连续性；首图依据现有原型高清重绘。","The interface prioritizes exceptions, low notification density, and continuity of responsibility. The lead visual is an HD reconstruction grounded in the existing prototype."],
      points:[["今天的任务始终可见。","Keep today's tasks visible."],["明确责任人和交接状态。","Make ownership and handoff state explicit."],["把提醒留给真正的异常。","Reserve notifications for genuine exceptions."]],
      media:[["/assets/household-care-coordination-redraw-hd.png","家庭协作主界面","Household coordination overview"],["/assets/household-steward-anonymized.png","脱敏的历史原型","Anonymized historical prototype"]],
      demo:"/tools/household-care/demo/"
    },
    "/tools/taskflow/":{
      accent:"#1570ef",soft:"#eaf3ff",kind:["工具项目","Tool project"],status:["可交互 Demo","Interactive demo"],
      title:["TaskFlow · 工作流与时长记录","TaskFlow · Workflow & Time Tracking"],
      deck:["把任务队列、当前工作、持续时长和完成历史放进同一条流程，让时间记录服务于工作推进。","Combining the task queue, current work, elapsed time, and completion history so time tracking supports the workflow."],
      section:["让时间记录成为工作流的一部分","Making time tracking part of the workflow"],
      body:["TaskFlow 把“正在做什么”放在页面中心，同时保留下一步和完成历史，减少在计时器与任务工具之间来回切换。","TaskFlow keeps the current task at the center while preserving next steps and completion history, reducing switching between timers and task tools."],
      role:["这是一个边界清楚的独立小产品，不与后来的注意力方法实验混为一谈。","A bounded standalone product, distinct from later attention-method experiments."],
      points:[["一次只突出当前任务。","Emphasize one current task at a time."],["在同一视图维护队列与历史。","Keep queue and history in the same view."],["让计时反馈支持推进，而不是制造负担。","Make timing feedback support progress instead of creating overhead."]],
      media:[["/assets/taskflow-single-task-timer-redraw-hd.png","TaskFlow 高清重绘界面","HD TaskFlow reconstruction"],["/assets/taskflow-reconstruction.png","历史原型视图","Historical prototype view"]],
      demo:"/tools/taskflow/demo/"
    },
    "/tools/workflow-recovery/":{
      accent:"#0e9384",soft:"#e8f7f4",kind:["工具项目","Tool project"],status:["可交互 Demo","Interactive demo"],
      title:["工作流续接与中断恢复系统","Workflow Continuity & Interruption Recovery System"],
      deck:["保留主任务、临时分支和准确返回位置，帮助人在被打断后快速恢复上下文。","Preserving the main task, temporary branch, and exact return point so people can resume without rebuilding context."],
      section:["把中断变成可以返回的临时分支","Turning interruptions into returnable temporary branches"],
      body:["系统显式记录主任务、临时分支和返回锚点，帮助用户区分“现在插入的事情”和“原本要继续的工作”。","The system explicitly records the main task, temporary branch, and return anchor so users can distinguish inserted work from the workflow they intend to resume."],
      role:["不同工具能缓解不同断裂点；目前没有一个方法能覆盖全部工作连续性问题。","Different tools relieve different breaks in continuity; no single method currently covers the whole problem."],
      points:[["保留中断前的准确返回位置。","Preserve the exact pre-interruption return point."],["把临时工作标记为分支。","Mark temporary work as a branch."],["恢复时先呈现最少但足够的上下文。","Show the minimum sufficient context on return."]],
      media:[["/assets/recovery-palette-demo-latest.png","当前可交互 Demo","Current interactive demo"],["/assets/branch-compass-portfolio.png","工作分支与返回锚点","Work branches and return anchors"]],
      demo:"/tools/workflow-recovery/demo/"
    },
    "/tools/structured-voice-input/":{
      accent:"#c11574",soft:"#fff0f7",kind:["工具项目","Tool project"],status:["日用改造","Daily adaptation"],
      title:["结构化语音输入软件","Structured Voice Input Software"],
      deck:["按一次键开始说话，本地转录后做保守的语义整理，再把文字送回正在使用的应用。","One key starts capture; local transcription is conservatively organized and returned to the active app."],
      section:["从语音到当前光标的一条连续输入链路","A continuous input path from speech to the active cursor"],
      body:["工作流保留原始转录与整理版本，在结构化失败时回退到原文，并尽量不改变说话者原有意思。","The workflow preserves both raw and organized transcripts, falls back to raw text when organization fails, and avoids changing the speaker's intended meaning."],
      role:["我定义并验证快捷键、模型选择、保守结构化、原文回退和返回当前光标的工作流，并制作 HandyBar 配置工具；底层应用与本地转录框架来自开源 Handy。","I defined and tested the shortcut, model choice, conservative organization, raw-text fallback, and return-to-cursor workflow, and built the HandyBar utility. The desktop app and local transcription foundation come from open-source Handy."],
      points:[["音频转录保持在本机。","Keep audio transcription on-device."],["整理前后文本都可恢复。","Keep both raw and organized text recoverable."],["失败时回到原文，不阻断输入。","Fall back to raw text without blocking input."]],
      media:[["/assets/handy-voice-input-workflow-hd.png","结构化语音输入工作流","Structured voice-input workflow"]]
    },
    "/concepts/synthetic-society/":{
      accent:"#6941c6",soft:"#f1edff",kind:["概念项目","Concept project"],status:["合成角色与事件","Synthetic personas and events"],
      title:["Synthetic Society · 合成社会实验场","Synthetic Society Lab"],
      deck:["把事件放进一座合成城市，观察不同人物如何重新理解它，以及这些理解如何改变选择、关系与后续影响。","Placing an event into a synthetic city to explore how different people reinterpret it and how those meanings reshape choices, relationships, and later consequences."],
      section:["用虚拟社会观察变化如何穿过关系网络","Using a virtual society to observe how change travels through relationships"],
      body:["概念原型把人物、事件、关系和时间线放在同一模拟环境中，用于探索产品假设在不同社会情境下可能产生的连锁反应。","The concept brings people, events, relationships, and timelines into one simulated environment to explore how product hypotheses may create different downstream effects across social contexts."],
      role:["概念、产品模型与信息可视化；所有人物、事件与结果均为合成内容。","Concept, product model, and information visualization; all people, events, and outcomes are synthetic."],
      points:[["把假设放进具体的城市情境。","Place hypotheses in a concrete city context."],["同时观察人物理解与关系变化。","Observe changes in both interpretation and relationships."],["明确区分模拟结果与现实证据。","Keep simulated outcomes distinct from real-world evidence."]],
      media:[["/assets/synthetic-observatory-18s.mp4","合成社会概念动画","Synthetic Society concept film","video"],["/assets/observatory-overview.jpg","实验场概览","Lab overview"],["/assets/observatory-linked-state.jpg","人物与事件的关联状态","Linked people and event state"]],
      links:[{href:"https://github.com/yangxiang5136/synthetic-society-observatory",zh:"GitHub ↗",en:"GitHub ↗"}]
    }
  };

  const zhButton=document.getElementById("detail-zh");
  const enButton=document.getElementById("detail-en");
  const root=document.getElementById("project-root");
  const key=location.pathname.endsWith("/")?location.pathname:location.pathname+"/";
  const project=projects[key];
  const requested=(new URLSearchParams(location.search).get("lang")||"").trim().toLowerCase();
  let language=requested==="en"?"en":(requested==="zh"||requested==="zh-cn")?"zh-CN":null;
  if(!language){try{language=localStorage.getItem("pf-lang")==="en"?"en":"zh-CN"}catch(error){language="zh-CN"}}
  const pick=value=>Array.isArray(value)?value[language==="en"?1:0]:value;
  function element(tag,className,text){const node=document.createElement(tag);if(className)node.className=className;if(text!==undefined)node.textContent=text;return node}
  function applyLanguage(next){
    language=next;document.documentElement.lang=next;zhButton.setAttribute("aria-pressed",String(next!=="en"));enButton.setAttribute("aria-pressed",String(next==="en"));
    render();
  }
  function setLanguage(next){
    try{localStorage.setItem("pf-lang",next)}catch(error){}
    applyLanguage(next);
  }
  function renderActions(target){
    const actions=element("div","hero-actions");
    if(project.demo){const link=element("a","action primary",language==="en"?"Open interactive demo ↗":"打开交互 Demo ↗");link.href=project.demo+(language==="en"?"?lang=en":"?lang=zh");actions.appendChild(link)}
    (project.links||[]).forEach(item=>{const link=element("a","action"+(item.primary?" primary":""),language==="en"?item.en:item.zh);link.href=item.href;link.target="_blank";link.rel="noopener noreferrer";actions.appendChild(link)});
    const back=element("a","action",language==="en"?"Back to all projects":"返回全部项目");back.href="/#atlas";actions.appendChild(back);target.appendChild(actions);
  }
  function render(){
    document.documentElement.style.setProperty("--accent",project?project.accent:"#175cd3");document.documentElement.style.setProperty("--accent-soft",project?project.soft:"#eaf1ff");
    document.querySelectorAll("[data-zh]").forEach(node=>node.style.display=language==="en"?"none":"");document.querySelectorAll("[data-en]").forEach(node=>node.style.display=language==="en"?"":"none");
    if(!project){root.replaceChildren();const box=element("section","route-error");const wrap=element("div");wrap.append(element("h1",null,"404"),element("p",null,language==="en"?"This project page does not exist.":"这个项目页面不存在。"));const back=element("a","action primary",language==="en"?"Back to portfolio":"返回作品集");back.href="/";wrap.appendChild(back);box.appendChild(wrap);root.appendChild(box);document.title="404 · Xiang Yang";return}
    document.title=pick(project.title)+" · 杨翔";root.replaceChildren();
    const hero=element("section","project-hero"),heroInner=element("div","hero-inner"),eyebrow=element("div","eyebrow");
    eyebrow.append(element("span",null,pick(project.kind)),element("span",null,pick(project.status)));heroInner.append(eyebrow,element("h1",null,pick(project.title)),element("p","project-deck",pick(project.deck)));renderActions(heroInner);hero.appendChild(heroInner);root.appendChild(hero);
    const body=element("section","project-body"),grid=element("div","detail-grid"),copy=element("div","project-copy"),role=element("aside","role-card");
    copy.append(element("p","section-label",language==="en"?"Project focus":"项目重点"),element("h2",null,pick(project.section)),element("p",null,pick(project.body)));
    const list=element("ul","principles");project.points.forEach(point=>list.appendChild(element("li",null,pick(point))));copy.appendChild(list);
    role.append(element("p","section-label",language==="en"?"Role & boundary":"角色与边界"),element("p",null,pick(project.role)));grid.append(copy,role);body.appendChild(grid);
    const media=element("div","media-grid");project.media.forEach(item=>{const figure=element("figure","media-card"+(item[3]==="contain"?" contain":""));let visual;if(item[3]==="video"){visual=document.createElement("video");visual.controls=true;visual.playsInline=true;visual.preload="metadata"}else{visual=document.createElement("img");visual.loading="lazy";visual.alt=language==="en"?item[2]:item[1]}visual.src=item[0];figure.append(visual,element("figcaption",null,language==="en"?item[2]:item[1]));media.appendChild(figure)});body.appendChild(media);
    if(project.demo){const demoSection=element("section","demo-section"),head=element("div","demo-head"),headingWrap=element("div");headingWrap.append(element("p","section-label",language==="en"?"Interactive prototype":"交互原型"),element("h2",null,language==="en"?"Try the workflow":"体验完整工作流"));const open=element("a","action",language==="en"?"Open full screen ↗":"全屏打开 ↗");open.href=project.demo+(language==="en"?"?lang=en":"?lang=zh");head.append(headingWrap,open);const frame=element("div","demo-frame"),iframe=document.createElement("iframe");iframe.src=open.href;iframe.loading="lazy";iframe.title=pick(project.title)+(language==="en"?" interactive demo":"交互 Demo");frame.appendChild(iframe);demoSection.append(head,frame);body.appendChild(demoSection)}
    root.appendChild(body);
  }
  zhButton.addEventListener("click",()=>setLanguage("zh-CN"));enButton.addEventListener("click",()=>setLanguage("en"));applyLanguage(language);
})();
