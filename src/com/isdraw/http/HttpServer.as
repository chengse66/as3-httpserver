package com.isdraw.http
{
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ServerSocketConnectEvent;
	import flash.net.ServerSocket;
	import flash.utils.Dictionary;

	[Event(name="newContext", type="com.isdraw.http.HttpEvent")] 
	public class HttpServer extends EventDispatcher
	{
		private var socket:ServerSocket;
		private var cache:Dictionary=new Dictionary(true);
		//-------------------事件
		public function HttpServer(host:String,port:int)
		{
			socket=new ServerSocket();
			socket.addEventListener(ServerSocketConnectEvent.CONNECT,_client_accept);
			socket.bind(port,host);
		}
		
		/**
		 * 连接客户端 
		 * @param e
		 */		
		private function _client_accept(e:ServerSocketConnectEvent):void{
			var context:HttpContext=new HttpContext(e.socket,e.socket.remoteAddress+":"+e.socket.remotePort);
			context.addEventListener(Event.COMPLETE,context_complete);
		}
		
		/**
		 * request处理结束 
		 * @param e
		 * 
		 */		
		private function context_complete(e:Event):void{
			var context:HttpContext=e.target as HttpContext;
			context.removeEventListener(Event.COMPLETE,context_complete);
			var h:HttpEvent=new HttpEvent(HttpEvent.NEW_CONTEXT);
			h.set_context(context);
			this.dispatchEvent(h);
			context.response.flush();
		}
		
		/**
		 * 启动 
		 */		
		public function start():void{
			socket.listen();
		}
	}
}