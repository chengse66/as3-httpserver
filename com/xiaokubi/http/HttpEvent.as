package com.xiaokubi.http
{
	import flash.events.Event;
	
	public class HttpEvent extends Event
	{
		/**
		 * 新的连接的接入 
		 */		
		public static const NEW_CONTEXT:String="newContext";
		
		private var _req:HttpRequest;
		private var _res:HttpResponse;
		
		public function HttpEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		public function get request():HttpRequest{return _req;}
		public function get response():HttpResponse{return _res;}
		internal function set_arguments(req:HttpRequest,res:HttpResponse):void{
			_req=req;
			_res=res;
		}
	}
}