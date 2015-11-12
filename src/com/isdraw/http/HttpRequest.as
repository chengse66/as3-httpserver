package com.isdraw.http
{
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;

	public class HttpRequest
	{
		//内部计数器
		private static var ID:int=0;
		public static const TEXT_PLAIN:String="text/plain";
		public static const TEXT_HTML:String="text/html";
		public static const APPLICATION_X_WWW_FORM_URLENCODED:String="application/x-www-form-urlencoded";
		public static const MULTIPART_FORM_DATA:String="multipart/form-data";
		public static const APPLICATION_OCTET_STREAM:String="application/octet-stream";
		public static const CONTENT_LENGTH:String="Content-Length";
		public static const CONTENT_TYPE:String="Content-Type";
		
		private const REG_URL:RegExp=/\?.*+$/g;
		private const REG_QUERYSTRING:RegExp=/([\w]+)\=([\w\%]+)/g;
		private const REG_LINE:RegExp=/^[\w\d\-]+/;
		private const REG_KEYPAIR:RegExp=/\w+\=\"[^"]+\"/g;

		private var socket:Socket;
		internal var _process_complete:Function;
		private var buffer:ByteArray=new ByteArray();
		private var line:int=0;
		private var state:Boolean=false;
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
		public var files:Object={};
		
		//缓冲文件
		private var cache_file:File;
		private var cache_stream:FileStream;
		
		//内部超时时钟
		private var _timeout:int=0;
		public function HttpRequest(socket:Socket)
		{
			this.socket=socket;
			cache_file=requireTmp();
			if(!cache_file.parent.exists) cache_file.parent.createDirectory();
			cache_stream=new FileStream();
			cache_stream.open(cache_file,FileMode.APPEND);
			this.reset_clock();
		}
		
		/**
		 * 重置时钟
		 */		
		private function reset_clock():void{
			clearTimeout(_timeout);
			_timeout=setTimeout(process_end,100);
		}
		
		/**
		 * 数据接收 
		 * @param e
		 */		
		internal function onData(e:ProgressEvent):void{
			this.reset_clock();
			if(!state){
				var b:int=0;
				while(socket.bytesAvailable>0){
					b=socket.readByte();
					if(b!=10){
						buffer.writeByte(b);
					}else{
						buffer.length--;
						if(buffer.length==0){
							state=true;
							parse_header_end();
							break;
						}else{
							parse_header_line(buffer.toString());
							buffer.clear();
						}
					}
				}
			}
			if(socket.bytesAvailable>0){
				socket.readBytes(buffer,0,socket.bytesAvailable);
				if(contentType==MULTIPART_FORM_DATA){
					cache_stream.writeBytes(buffer,0,buffer.length);
					buffer.clear();
				}
			}
		}
		
		
		/**
		 * 处理文件头 
		 */		
		private function parse_header_end():void{
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
		}
		
		/**
		 * 处理头部 
		 * @param text
		 * 
		 */		
		private function parse_header_line(text:String):void{
			var a:Object=text.match(REG_LINE);
			if(a.length!=1 || a.index!=0) return;
			var b:String=String(a[0]).toLowerCase();
			if(b=="post" || b=="get"){
				//第一行
				var c:Array=text.split(/\s+/);
				if(c.length==3){
					method=c[0];
					rawURL=c[1];
					version=c[2];
					url=rawURL.replace(REG_URL,"");
					parse_data(rawURL,queryString);
				}
			}else{
				var poz:int=text.indexOf(": ");
				if(poz>0) header[text.substring(0,poz)]=text.substring(poz+2);
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
		 * 读写完成 
		 * @param text
		 */		
		private function process_end():void{
			cache_stream.close();
			parse_body();
			var text:String=buffer.readUTFBytes(buffer.bytesAvailable);
			parse_data(text,post);
			_process_complete();
			buffer.clear();
			if(cache_file.exists) cache_file.deleteFile();
		}
		
		/**
		 * 处理内容
		 **/
		private function parse_body():void{
			switch(contentType){
				case APPLICATION_OCTET_STREAM:
					break;
				case APPLICATION_X_WWW_FORM_URLENCODED:
					parse_data(buffer.toString(),post);
					break;
				case MULTIPART_FORM_DATA:
					parse_form_data();
					break;
			}
		}
		
		/**
		 * 处理正文数据 
		 */		
		private function parse_form_data():void{
			if(!cache_file.exists) return;
			cache_stream.open(cache_file,FileMode.READ);
			var bs:ByteArray=new ByteArray();
			bs.writeUTFBytes("--"+this.boundary+"\r\n");
			
			var flist:Vector.<File>=new Vector.<File>();
			var b:int,i:int,blen:int=bs.length;
			var tmp:File;
			var tmpfs:FileStream;
			var tmpcache:ByteArray=new ByteArray();
			var iscf:int=0;
			while(cache_stream.bytesAvailable>0){
				for(i=0;i<bs.length;i++){
					if(cache_stream.bytesAvailable>0){
						b=cache_stream.readByte();
						tmpcache.writeByte(b);
						if(b!=bs[i]) break;
					}else{
						break;
					}
				}
				if(tmpcache.length==0){
					break;
				}else if(tmpcache.length==bs.length){
					if(tmpfs==null){
						bs.clear();
						bs.writeUTFBytes("\r\n--"+this.boundary);
						tmpfs=new FileStream();
					}else{
						tmpfs.close();
					}
					
					if(cache_stream.bytesAvailable>=20){
						tmp=requireTmp("cache_");
						flist.push(tmp);
						//cache_stream.position+=2;
						var ds:String=stream_read_line(cache_stream);
						
						var sps:Array=ds.match(REG_KEYPAIR);
						var file:FileObject=new FileObject();
						//处理files
						var a:String,ii:int;
						if(sps.length>=2){
							for(i=0;i<sps.length;i++){
								a=sps[i].replace(/[\'\"]/g,"");
								ii=a.indexOf("=");
								if(ii>0){
									file[a.substring(0,ii)]=a.substring(ii+1);
								}
							}
						}
						ds=stream_read_line(cache_stream);
						var poz:int=ds.indexOf(": ");
						if(poz>0) file.contentType=ds.substring(poz+2);
						file.tmpFile=tmp.nativePath;
						files[file.name]=file;
						stream_read_line(cache_stream);
					}else{
						break;
					}
					
					tmpfs.open(tmp,FileMode.APPEND);
				}else{
					cache_stream.position-=tmpcache.length-1;
					if(tmpfs!=null){
						tmpfs.writeBytes(tmpcache,0,1);
					}
				}
				tmpcache.clear();
			}
			cache_stream.close();
		}
		
		/**
		 * 读取一行 
		 * @return 
		 */		
		private function stream_read_line(stream:FileStream):String{
			var b:ByteArray=new ByteArray();
			var c:int;
			while(stream.bytesAvailable>0){
				c=stream.readByte();
				if(c==13){
					if(stream.bytesAvailable>0){
						stream.position++;
					}
					break;
				}
				b.writeByte(c);
			}
			return b.toString();
		}
		
		/**
		 * 请求一个临时文件 
		 * @return 
		 */		
		private function requireTmp(tab:String=""):File{
			return File.applicationStorageDirectory.resolvePath("http_cache/"+tab+String(new Date().time)+String(ID++)+".tmp");
		}
	}
	
}