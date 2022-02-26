function testIsPathInside($root, $path = $PWD) {
 	(fullpath($path)).StartsWith((fullpath($root)), [StringComparison]::OrdinalIgnoreCase)
}
