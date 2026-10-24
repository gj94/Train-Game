extends RefCounted
## Shared finite-difference normals on the existing terrain lattice. Geometry
## stays unchanged; fine bank vertices interpolate the same coarse normals.
var sample: Callable
var spacing: float
var grid:={}
var points:={}
func _init(height_sample: Callable,grid_spacing: float=8.0):
	sample=height_sample;spacing=grid_spacing
func lattice(key: Vector2i) -> Vector3:
	if grid.has(key):return grid[key]
	var p:=Vector2(key)*spacing
	var dx: float=sample.call(p.x+spacing,p.y)-sample.call(p.x-spacing,p.y)
	var dz: float=sample.call(p.x,p.y+spacing)-sample.call(p.x,p.y-spacing)
	var normal:=Vector3(-dx,spacing*2,-dz).normalized()
	grid[key]=normal;return normal
func at(p: Vector2) -> Vector3:
	if points.has(p):return points[p]
	var cell:=Vector2i(floori(p.x/spacing),floori(p.y/spacing))
	var weight:=p/spacing-Vector2(cell)
	var normal:=lattice(cell)
	if weight.length_squared()>.0000001:
		var lower:=normal.lerp(lattice(cell+Vector2i(1,0)),weight.x)
		var upper:=lattice(cell+Vector2i(0,1)).lerp(lattice(cell+Vector2i(1,1)),weight.x)
		normal=lower.lerp(upper,weight.y).normalized()
	points[p]=normal;return normal
