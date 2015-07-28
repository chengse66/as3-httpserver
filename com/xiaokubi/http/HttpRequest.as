package com.xiaokubi.http
{
	import flash.events.ProgressEvent;
	import flash.filesystem.FileStream;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;

	public class HttpRequest
	{
		public static const TEXT_PLAIN:String="text/plain";
		public static const TEXT_HTML:String="text/html";
		public static const APPLICATION_X_WWW_FORM_URLENCODED:String="application/x-www-form-urlencoded";
		public static const MULTIPART_FORM_DATA:String="multipart/form-data";
		public static const APPLICATION_OCTET_STREAM:String="application/octet-stream";
		public static const CONTENT_LENGTH:String="Content-Length";
		public static const CONTENT_TYPE:String="Content-Type";
		
		private const REG_URL:RegExp=/\?.*+$/g;
		private const REG_QUERYSTRING:RegExp=/([\w]+)\=([\w\%]+)/g;
		
		private var socket:Socket;
		internal var _process_complete:Function;
		private var buffer:ByteArray=new ByteArray();
		private var line:int=0;
		private var state:int=0;
		private var timerID:int=0;
		private var boundary:String;
		//对外属性
		public var url:String;
		public var rawURL:String;
		public var method:String;
		public var version:String;
		public var header:Object={};
		public var contentLength:int=0;
		public var contentType:String=TEXT_HTML;
		public var queryString:Object={};
		public var post:Object={};
		
		public function HttpRequest(socket:Socket)
		{
			this.socket=socket;
		}

		/**
		 * 数据接收 
		 * @param e
		 */		
		internal function onData(e:ProgressEvent):void{
			clearTimeout(timerID);
			timerID=setTimeout(process_end,50);
			if(state==0){
				var b:int=0;
				var text:String;
				while(socket.bytesAvailable>0){
					b=socket.readByte();
					if(b==13){
						b=socket.readByte();
						buffer.position=0;
						text=buffer.readUTFBytes(buffer.length);
						if(text==""){
							buffer.length=0;
							process_header();
							break;
						}else{
							buffer.length=0;
							process_header_line(text);
						}
						line++;
					}else{
						buffer.writeByte(b);
					}
				}
			}
			
			if(state==1){
				process_body();
			}
		}
		
		/**
		 * 处理头部 
		 * @param text
		 * 
		 */		
		private function process_header_line(text:String):void{
			var _list:Array;
			var key:String;
			var value:String;
			
			if(line==0){
				//检测头部
				_list=text.split(' ');
				if(_list.length==3){
					method=_list[0];
					rawURL=_list[1];
					version=_list[2];
					url=rawURL.replace(REG_URL,"");
					parse_data(rawURL,queryString);
				}
			}else{
				var poz:int=text.indexOf(": ");
				if(poz>0){
					key=text.substring(0,poz);
					value=text.substring(poz+2);
					header[key]=value;
				}
			}
		}
		
		/**
		 * 处理字符post get数据 
		 * @param text
		 * @param data
		 * 
		 */			
		private function parse_data(text:String,data:Object):void{
			var list:Array=text.match(REG_QUERYSTRING);
			if(list!=null){
				for(var i:int=0;i<list.length;i++){
					var _list:Array=list[i].split('=');
					if(_list.length==2){
						data[_list[0]]=_list[1];
					}
				}
			}
		}
		
		/**
		 * 处理文件头 
		 */		
		private function process_header():void{
			if(header[CONTENT_LENGTH]){
				contentLength=int(header[CONTENT_LENGTH]);
			}else{
				contentLength=1024*512;
			}
			if(header[CONTENT_TYPE]){
				var _l:Array=header[CONTENT_TYPE].split('; boundary=');
				if(_l.length==2){
					contentType=_l[0];
					boundary=_l[1];
				}else{
					contentType=header[CONTENT_TYPE];
				}
			}
			
			state=1;
		}
		
		/**
		 * 处理文档具体内容
		 */		
		private function process_body():void{
			socket.readBytes(buffer,0,socket.bytesAvailable);
		}
		
		/**
		 * 读写完成 
		 * @param text
		 */		
		private function process_end():void{
			buffer.position=0;
			var text:String=buffer.readUTFBytes(buffer.bytesAvailable);
			parse_data(text,post);
			_process_complete();
			buffer.clear();
		}
	}
	
}
import flash.utils.ByteArray;

/**
 * 内存流 
 * @author Administrator
 * 
 */	
class MemoryStream extends ByteArray{
	private var newLine:ByteArray=new ByteArray();
	public function MemoryStream(){
		newLine.writeUTFBytes("\r\n");
		newLine.position=0;
	}
	
	public function readLine():String
	{
		var index:int = indexOfBytes(newLine);
		var result:String = null;
		if (index != -1)
		{
			result = this.readUTFBytes(index-this.position);
			this.position += newLine.length;
		}
		
		return result;
	}
	
	/**
	 * 删除指定的位置 
	 * @param start
	 * @param length
	 * 
	 */	
	public function remove(start:uint, length:uint):void
	{
		if (start + length >= this.length)
		{
			this.clear();
		}else{
			var tmp:ByteArray = new ByteArray();
			tmp.writeBytes(this, start + length);
			
			this.clear();
			
			this.writeBytes(tmp);
			this.position = 0;
			
			tmp.clear();
			
		}
	}
	
	/**
	 * 查找字符出现的位置 
	 * @param str
	 * @return 
	 * 
	 */	
	public function indexOfString(str:String):int
	{
		var by:ByteArray = new ByteArray();
		by.writeUTFBytes(str);
		by.position = 0;
		return indexOfBytes(by);
	}
	
	/**
	 * 查询字节数组出现的位置 
	 * @param by
	 * @return 
	 * 
	 */	
	public function indexOfBytes(by:ByteArray):int
	{
		var index:int = -1;
		if (length-this.position < by.length) return index;
		
		for (var i:int = position; i < length; i++ )
		{
			for (var n:int = 0; n < by.length; n++ )
			{
				index = i + n;
				if (index >= length || this[index] != by[n])
				{
					index = -1;
					break;
				}
			}
			if (index != -1)
				break;
		}
		if (index == -1)
		{
			this.position = this.length - by.length;
		}else
		{
			index -= by.length-1;
		}
		return index;
	}
}