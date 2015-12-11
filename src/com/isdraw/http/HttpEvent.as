package com.isdraw.http
{
	import flash.events.Event;
	
	public class HttpEvent extends Event
	{
		/**
		 * 新的连接的接入 
		 */		
		public static const NEW_CONTEXT:String="newContext";
		
		private var _context:HttpContext;
		
		public function HttpEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		public function get context():HttpContext{
			return _context;
		}
		
		internal function set_context(m:HttpContext):void{
			this._context=m;
		}
	}
}