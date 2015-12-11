package com.isdraw.http
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.OutputProgressEvent;
	import flash.events.ProgressEvent;
	import flash.net.Socket;

	[Event(name="complete", type="flash.events.Event")]
	public class HttpContext extends EventDispatcher
	{
		private var _request:HttpRequest;
		private var _response:HttpResponse;
		private var _clientID:String;
		private var _socket:Socket;

		public function HttpContext(socket:Socket,clientID:String)
		{
			this._socket=socket;
			this._clientID=clientID;
			_request=new HttpRequest(_socket);
			_response=new HttpResponse(_socket);
			_request.addEventListener(Event.COMPLETE,request_complete);
		}
		
		private function request_complete(e:Event):void{
			_request.removeEventListener(Event.COMPLETE,request_complete);
			this.dispatchEvent(new Event(Event.COMPLETE));
		}
		
		public function get request():HttpRequest{return _request;}
		public function get response():HttpResponse{return _response;}
		public function get clientID():String{return _clientID;}
	}
}