package com.isdraw.http
{
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.net.Socket;

	/**
	 * @author isdraw.com
	 * http context
	 */	
	public class HttpContext
	{
		private var _request:HttpRequest;
		private var _response:HttpResponse;
		private var _clientID:String;
		private var _socket:Socket;
		internal var _local_closed:Function;
		internal var _local_parse_success:Function;
		
		public function HttpContext(socket:Socket,clientID:String)
		{
			var _this:HttpContext=this;
			this._socket=socket;
			this._clientID=clientID;
			socket.addEventListener(Event.CLOSE,onClose);
			socket.addEventListener(ProgressEvent.SOCKET_DATA,onData);
			_request=new HttpRequest(_socket);
			_request._process_complete=function():void{
				_local_parse_success();				
				response.flush();
			};
			_response=new HttpResponse(_socket);
		}
		
		/**
		 * 断开连接部分 
		 * @param e
		 **/		
		private function onClose(e:Event):void{
			_socket.removeEventListener(Event.CLOSE,onClose);
			_socket.removeEventListener(ProgressEvent.SOCKET_DATA,onData);
			if(_local_closed!=null) _local_closed();
		}
		
		private function onData(e:ProgressEvent):void{
			_request.onData(e);
		}
		
		public function get request():HttpRequest{return _request;}
		public function get response():HttpResponse{return _response;}
		public function get clientID():String{return _clientID;}
	}
}