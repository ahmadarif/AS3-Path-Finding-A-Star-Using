package  
{
	import flash.desktop.NativeApplication;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import flash.utils.Timer;
	
	/**
	 * ...
	 * @author Gambite Studio - Ahmad Arif
	 */
	public class Main extends Sprite 
	{
		private const JUM_TILE_X:uint = 20;
		private const JUM_TILE_Y:uint = 12;
		private const TILE_WIDTH:uint = 40;
		private const MIN_DISTANCE:uint = 15;
		
		private const COLOR_START:uint = 0x00ff00;
		private const COLOR_START_HOVER:uint = 0x006633;
		private const COLOR_FINISH:uint = 0xff0000;
		private const COLOR_CURRENT:uint = 0x0000ff;
		private const COLOR_PATH:uint = 0xcccccc;
		private const COLOR_CLEAR:uint = 0xffffff;
		private const COLOR_BLOCK:uint = 0x000000;
		private const COLOR_NO_WAY:uint = 0xff00ff;
		
		private var canvas:Sprite;
		private var startPoint:Point;
		private var endPoint:Point;
		private var currPoint:Point;
		private var tile:Vector.<Vector.<Tiles>>;
		private var path:Vector.<Point>;
		private var timer:Timer = new Timer(100);
		
		private var isDiagonalCheck:Boolean = true;
		
		public function Main():void 
		{
			setupStage();
			setupScreen();
		}
		
		private function setupStage():void 
		{
			stage.scaleMode = StageScaleMode.SHOW_ALL;
			stage.align = StageAlign.TOP;
			stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			stage.stageWidth = 800;
			stage.stageHeight= 480;
			stage.addEventListener(Event.DEACTIVATE, function(e:Event):void
			{
				//NativeApplication.nativeApplication.exit();
			});
			stage.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):void
			{
				if (e.keyCode == Keyboard.BACK)
				{
					NativeApplication.nativeApplication.exit();
				}
			});
		}
		
		private function setupScreen():void 
		{
			canvas = new Sprite();
			addChild(canvas);
			
			fieldSetup();
			drawGrid();
			findPath();
			
			stage.addEventListener(MouseEvent.CLICK, addWall);
		}
		
		/* melakukan pengaturan terhadap field, semua tile diseting ke nilai defaultnya
		 * bisa dilewati
		 * bukan startPoint
		 * bukan endPoint
		 * belum pernah dikunjungi
		 **/
		private function fieldSetup():void 
		{			
			// membuat matriks tile
			tile = new Vector.<Vector.<Tiles>>();
			for (var i:uint = 0; i < JUM_TILE_X; i++)
			{
				tile[i] = new Vector.<Tiles>();
				
				for (var j:uint = 0; j < JUM_TILE_Y; j++)
				{
					tile[i][j] = new Tiles();
					tile[i][j].walkable = true;
					tile[i][j].startPoint = false;
					tile[i][j].endPoint = false;
					tile[i][j].visited = false;
				}
			}
			
			// random startPoint
			startPoint = new Point(Math.floor(Math.random() * JUM_TILE_X), Math.floor(Math.random() * JUM_TILE_Y));
			tile[startPoint.x][startPoint.y].startPoint = true;
			tile[startPoint.x][startPoint.y].visited = true;
			
			// random endPoint, endPoint diatur minimal berjarak 10 tile dari startPoint
			do {
				endPoint = new Point(Math.floor(Math.random() * JUM_TILE_X), Math.floor(Math.random() * JUM_TILE_Y));
			} while (manhattan(startPoint, endPoint) < MIN_DISTANCE);
			tile[endPoint.x][endPoint.y].endPoint = true;
		}
		
		private function drawGrid():void 
		{
			canvas.graphics.clear();
			canvas.graphics.lineStyle(1, 0x999999);
			
			for (var i:uint = 0; i < JUM_TILE_X; i++)
			{
				for (var j:uint = 0; j < JUM_TILE_Y; j++)
				{
					// warna awal adalah putih
					drawTile(i, j, COLOR_CLEAR);
					
					// jika tidak bisa dilewati maka berwarna hitam
					if (!tile[i][j].walkable) drawTile(i, j, COLOR_BLOCK);
					
					// jika merupakan startPoint maka berwarna hijau
					if (tile[i][j].startPoint) drawTile(i, j, COLOR_START);
					
					// jika merupakan endPoint maka berwarna merah
					if (tile[i][j].endPoint) drawTile(i, j, COLOR_FINISH);
				}
			}
		}
		
		private function drawTile(x:uint, y:uint, color:Number):void 
		{
			canvas.graphics.beginFill(color, 1);
			canvas.graphics.drawRect(x * TILE_WIDTH, y * TILE_WIDTH, TILE_WIDTH, TILE_WIDTH);
			canvas.graphics.endFill();
		}
		
		private function findPath():void 
		{
			path = new Vector.<Point>();
			path.push(startPoint);
			
			for (var i:uint = 0; i < JUM_TILE_X; i++)
			{
				for (var j:uint = 0; j < JUM_TILE_Y; j++)
				{
					tile[i][j].visited = false;
				}
			}
			
			currPoint = new Point(startPoint.x, startPoint.y);
			timer.addEventListener(TimerEvent.TIMER, walk);
			timer.start();
		}
		
		private function walk(e:TimerEvent):void 
		{
			var minValue:Number = 999999; // menampung nilai terkecil untuk perhitungan jarak
			var dir:Number; // jarak ke endPoint
			var savedPoint:Point = null;
			
			// lakukan pengecekan ke posisi diantara currPoint
			for (var i:int = -1; i <= 1; i++)
			{
				for (var j:int = -1; j <= 1; j++)
				{
					// lakukan pengecekan diagonal
					if (isDiagonalCheck)
					{
						/* tile akan dicek jika:
						 * berada diarea grid
						 * bisa dilewati (bukan tembok)
						 * belum pernah dikunjungi
						 */
						if (insideField(i, j, currPoint) && tile[currPoint.x + i][currPoint.y + j].walkable && !tile[currPoint.x + i][currPoint.y + j].visited)
						{	
							// jarak dari area tile ke endPoint
							dir = manhattan(new Point(currPoint.x + i, currPoint.y + j), endPoint);
							
							// tile disinggahi adalah tile yang memiliki jarak terdekat dengan endPoint
							if (dir < minValue)
							{
								minValue = dir;
								savedPoint = new Point(currPoint.x + i, currPoint.y + j);
							}
						}
					}
					else
					{
						// diagonal tidak dicek
						if ((i != 0 && j == 0) || (i == 0 && j != 0))
						{
							/* tile akan dicek jika:
							 * berada diarea grid
							 * bisa dilewati (bukan tembok)
							 * belum pernah dikunjungi
							 */
							if (insideField(i, j, currPoint) && tile[currPoint.x + i][currPoint.y + j].walkable && !tile[currPoint.x + i][currPoint.y + j].visited)
							{	
								// jarak dari area tile ke endPoint
								dir = manhattan(new Point(currPoint.x + i, currPoint.y + j), endPoint);
								
								// tile disinggahi adalah tile yang memiliki jarak terdekat dengan endPoint
								if (dir < minValue)
								{
									minValue = dir;
									savedPoint = new Point(currPoint.x + i, currPoint.y + j);
								}
							}
						}
					}
				}
			}
			
			/*
			 * Jika savedPoint ditemukan atau tidak sama dengan null, maka lakukan proses berikutnya
			 * Jika tidak ditemukan maka lakukan proses backtrack atau kembali ke tile sebelumnya.
			 **/
			if (savedPoint != null)
			{
				// lanjutkan
				if (savedPoint.x != endPoint.x || savedPoint.y != endPoint.y)
				{
					drawTile(savedPoint.x, savedPoint.y, COLOR_CURRENT);
				}
				
				// ganti currPoint dengan savedPoint, tandai tile sudah dilewati
				tile[savedPoint.x][savedPoint.y].visited = true;
				currPoint = savedPoint;
				path.push(currPoint);
				
				// mengubah warna jalan sebelumnya
				if (path.length > 2)
				{
					if (path[path.length - 2].x == startPoint.x && path[path.length - 2].y == startPoint.y)
					{
						// jika sama dengan startPoint
						drawTile(path[path.length - 2].x, path[path.length - 2].y, COLOR_START_HOVER);
					}
					else
					{
						// jika tidak sama dengan startPoint
						drawTile(path[path.length - 2].x, path[path.length - 2].y, COLOR_PATH);
					}
				}
				
				// jika sudah ketemu maka game berhenti melakukan pencarian
				if (currPoint.x == endPoint.x && currPoint.y == endPoint.y)
				{
					drawTile(currPoint.x, currPoint.y, COLOR_NO_WAY);
					timer.removeEventListener(TimerEvent.TIMER, walk);
				}
			}
			else
			{
				// lakukan backtrack
				if (path.length > 1)
				{
					currPoint = path[path.length - 2];
					drawTile(currPoint.x, currPoint.y, COLOR_CURRENT);
					
					if (path[path.length - 1].x == startPoint.x && path[path.length - 1].y == startPoint.y)
					{
						drawTile(path[path.length - 1].x, path[path.length - 1].y, COLOR_START);
					}
					else
					{
						drawTile(path[path.length - 1].x, path[path.length - 1].y, COLOR_CLEAR);
					}
					
					path.pop();
				}
				else
				{
					// tidak ada solusi
					drawTile(currPoint.x, currPoint.y, COLOR_NO_WAY);
					timer.removeEventListener(TimerEvent.TIMER, walk);
				}
			}
		}
		
		private function insideField(x:int, y:int, p:Point):Boolean 
		{
			if (p.x + x >= JUM_TILE_X || p.x + x < 0 || p.y + y >= JUM_TILE_Y || p.y + y < 0)
			{
				return false;
			}
			
			return true;
		}
		
		private function addWall(e:MouseEvent):void 
		{
			var clickX:Number = Math.floor(mouseX / TILE_WIDTH);
			var clickY:Number = Math.floor(mouseY / TILE_WIDTH);
			
			if (!tile[clickX][clickY].startPoint && !tile[clickX][clickY].endPoint)
			{
				tile[clickX][clickY].walkable = !tile[clickX][clickY].walkable;
			}
			else
			{
				timer.removeEventListener(TimerEvent.TIMER, walk);
				fieldSetup();
			}
			
			drawGrid();
			findPath();
		}
		
		// mencari jarak antara dua titik mengguanakn metode manhattan
		private function manhattan(p1:Point, p2:Point):Number
		{
			return Math.abs(p1.x - p2.x) + Math.abs(p1.y - p2.y);
		}
		
		private function ecluidian(p1:Point, p2:Point):Number
		{
			return Math.sqrt(Math.pow(p1.x - p2.x, 2) + Math.pow(p1.y - p2.y, 2));
		}
	}
	
}

class Tiles
{
	public var walkable:Boolean;
	public var startPoint:Boolean;
	public var endPoint:Boolean;
	public var visited:Boolean;
}
