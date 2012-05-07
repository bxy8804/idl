
;\\ BUILD A ZONEMAP FROM EITHER ANNULAR SEGMENTS OR A REGULAR GRID
;\\ annular = {xsize:0, ysize:0, xcenter:0, ycenter:0, radii:[], sectors:[]}
;\\ grid = {xsize:0, ysize:0, xwidth:0, ywidth:0, xcenter:0, ycenter:0, max_radius:0.0}
function zonemap_builder, annular=annular, $
				 		  grid=grid, $
				 		  zone_centers=zone_centers, $
				 		  zone_pixel_count=zone_pixel_count



	;\\ BUILD A ZONEMAP OUT OF CONCENTRIC ANNULI
	if keyword_set(annular) then begin

			secs = annular.sectors
			rads = annular.radii
			nx = annular.xsize
			ny = annular.ysize
			cent = [annular.xcenter, annular.ycenter]

			nums = secs
			nums(0) = 0
			for n = 1, n_elements(secs) - 1 do nums(n) = total(secs(0:n-1))

			zone = intarr(nx,ny)
			zone[*] = -1
			zone_xcen = [-1]
			zone_ycen = [-1]
			zone_pixel_count = [-1]

			;\\ Make a distance map from [cent(0),cent(1)]
				calidx = findgen(n_elements(zone))
				calxx = (calidx mod nx) - cent(0)
				calyy = fix(calidx / nx) - cent(1)
				calx = fltarr(nx,ny)
				calx(*) = calxx
				caly = calx
				caly(*) = calyy
				caldist = sqrt(calx*calx + caly*caly)
				caldist = caldist / float(nx/2.)

			;\\ Make an angle map
				calang = atan(caly,calx)
				pts = where(calang lt 0, npts)
				if npts gt 0 then calang(pts) = calang(pts) + (2*!PI)

			zcount = 0
			for ridx = 0, n_elements(rads) - 2 do begin
				lower_dist = rads(ridx)
				upper_dist = rads(ridx+1)
				circ = where(caldist ge lower_dist and caldist lt upper_dist, ncirc)

				if ncirc gt 0 then begin
					nsecs = secs(ridx)
					angles = findgen(nsecs+1) * (360./nsecs) * !dtor
					for sidx = 0, nsecs - 1 do begin
						lower_ang = angles[sidx]
						upper_ang = angles[sidx+1]
						seg = where(calang[circ] ge lower_ang and calang[circ] lt upper_ang, nseg)
						if nseg gt 0 then begin
							zone[circ[seg]] = zcount
							zone_xcen = [zone_xcen, mean(calxx[circ[seg]])]
							zone_ycen = [zone_ycen, mean(calyy[circ[seg]])]
							zone_pixel_count = [zone_pixel_count, nseg]
							zcount ++
						endif
					endfor
				endif
			endfor

			zone_xcen = zone_xcen[1:*] + cent[0]
			zone_ycen = zone_ycen[1:*] + cent[1]
			zone_centers = [[zone_xcen],[zone_ycen]]
			zone_pixel_count = zone_pixel_count[1:*]
			return, zone

	endif


	;\\ BUILD A ZONEMAP OUT OF RECTANGLES (A REGULAR GRID)
	if keyword_set(grid) then begin

		nx = grid.xsize
		ny = grid.ysize
		xw = grid.xwidth
		yw = grid.ywidth
		cent = [grid.xcenter, grid.ycenter]

		zone = intarr(nx,ny)
		zone(*) = -1

		;\\ Make a distance map from [cent(0),cent(1)]
			calidx = findgen(n_elements(zone))
			calxx = (calidx mod nx) - cent(0)
			calyy = fix(calidx / nx) - cent(1)
			calx = fltarr(nx,ny)
			calx(*) = calxx
			caly = calx
			caly(*) = calyy
			caldist = sqrt(calx*calx + caly*caly)
			caldist = caldist / float(nx/2.)

		nx_rects = fix(nx) / fix(xw)
		ny_rects = fix(ny) / fix(yw)

		zone = congrid(indgen(nx_rects, ny_rects), nx, ny)
		pts = where(caldist gt grid.max_radius, npts, complement=in_pts)
		if npts gt 0 then zone[pts] = -1

		return, zone

	endif
end