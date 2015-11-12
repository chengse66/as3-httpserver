package com.isdraw.http
{
	
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
			context._local_parse_success=function():void{
				var handle:HttpEvent=new HttpEvent(HttpEvent.NEW_CONTEXT);
				handle.set_arguments(context.request,context.response);
				dispatchEvent(handle);
			};
			cache[context.clientID]=context;
			context._local_closed=function():void{delete cache[context.clientID];}
		}
		
		/**
		 * 启动 
		 */		
		public function start():void{
			socket.listen();
		}
	}
}