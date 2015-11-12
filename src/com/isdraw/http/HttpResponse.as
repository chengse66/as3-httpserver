package com.isdraw.http
{
	import flash.net.Socket;
	import flash.utils.ByteArray;

	public class HttpResponse extends ByteArray
	{
		private var socket:Socket;
		public var header:Object={};
		public var statusCode:int=200;
		public var contentType:String="text/html";
		
		public function HttpResponse(socket:Socket)
		{
			this.socket=socket;	
		}
		
		/**
		 * 获取状态数据 
		 * @param code
		 * 
		 */		
		private function get_status_name(code:uint):String{
			var text:String="OK";
			switch(code){
				case 200:
					text="OK";
					break;
				case 403:
					text="Forbidden";
					break;
				case 404:
					text="Not Found";
					break;
				case 500:
				default:
					text="Internal Server Error";
					break;
			}
			return code+" OK";
		}
		
		/**
		 * 输出内容到缓冲区 
		 */		
		internal function flush():void{
			if(socket.connected){
				socket.writeUTFBytes("HTTP/1.1 "+get_status_name(statusCode)+"\r\n");
				socket.writeUTFBytes("Content-Type: "+contentType+"\r\n");
				socket.writeUTFBytes("Content-Length:"+this.length+"\r\n");
				socket.writeUTFBytes("\r\n");
				
				this.position=0;
				socket.writeBytes(this,0,this.bytesAvailable);
				socket.flush();
				socket.close();
				this.clear();
			}
		}
	}
}