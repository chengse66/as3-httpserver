package com.isdraw.http
{
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;

	internal class HttpRequestReader
	{
		private var ms:IDataInput;
		private var mb:ByteArray;
		private var crlf:Boolean;
		public var byteReaded:int=0;
		public function HttpRequestReader(stream:IDataInput)
		{
			this.ms=stream;	
			mb=new ByteArray();
		}
		
		/**
		 * 尝试读取一整行 
		 * @return 当前是否整行
		 */		
		public function readLine():Boolean{
			if(crlf){
				mb.clear();
				crlf=false;
			}
			var b:int;
			while(ms.bytesAvailable>0){
				b = ms.readByte(); 
				byteReaded++;
				if(b!=13){
					buffer.writeByte(b);
				}else{
					if(ms.bytesAvailable>0){
						b = ms.readByte();
						byteReaded++;
						if(b!=10){
							buffer.writeByte(13);
							buffer.writeByte(b);
						}else{
							crlf=true;
							break;
						}
					}
				}
			}
			return crlf;
		}
		
		/**
		 * 回收和销毁数据  
		 */		
		public function dispose():void{
			buffer.clear();
		}
		
		/**
		 * 获取当前的缓冲数据池 
		 * @return 
		 */		
		public function get buffer():ByteArray{
			return mb;
		}
	}
}