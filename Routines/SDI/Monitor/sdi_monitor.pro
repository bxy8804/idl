
;\\ Clear the calibration data for given site (force it to refresh when the
;\\ next calibration snapshot arrives). Clears all calibration for all zonemaps.
pro sdi_monitor_clear_calibration, site ;\\ site code

	common sdi_monitor_common, global, persistent

	if ptr_valid(persistent.snapshots) eq 0 then return

	snaps = *persistent.snapshots
	match = where(strlowcase(snaps.site_code) eq strlowcase(site) and $
				  snaps.wavelength eq 6328, nm)
	if nm eq 0 then return

	new_snaps = delete_elements(snaps, match)
	*persistent.snapshots = new_snaps

end

;\\ Clear all saved timeseries data for the current day and site
pro sdi_monitor_clear_timeseries, site ;\\ site code

	common sdi_monitor_common, global, persistent

	ts_files = file_search(global.home_dir + '\Timeseries\' + site + '_timeseries.idlsave', count = n_series)
	print, ts_files

	for i = 0, n_series - 1 do begin
		restore, ts_files[i]

		js2ymds, series.start_time, y, m, d, s
		dayno = ymd2dn(y, m, d)

		curr_year = float( dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='Y$'))
		curr_dayn = float( dt_tm_fromjs(dt_tm_tojs(systime(/ut)), format='doy$'))
		keep = where(y eq curr_year and dayno eq curr_dayn, nkeep)
		if nkeep gt 0 then begin
			series = series[keep]
			save, filename = ts_files[i], series, meta
		endif else begin
			;\\ What to do here, delete file?
		endelse
	endfor

end

;\\ Return the status structure for a given job
function sdi_monitor_job_status, job

	common sdi_monitor_common, global, persistent

	match = (where(strlowcase(global.job_status.name) eq strlowcase(job), nmatch))[0]
	return, global.job_status[match]
end

;\\ Update the last run field of a given job
pro sdi_monitor_job_timeupdate, job

	common sdi_monitor_common, global, persistent

	match = (where(strlowcase(global.job_status.name) eq strlowcase(job), nmatch))[0]
	global.job_status[match].last_run = systime(/sec)
end

;\\ Return the time in seconds since last job run
function sdi_monitor_job_timelapse, job

	common sdi_monitor_common, global, persistent

	match = (where(strlowcase(global.job_status.name) eq strlowcase(job), nmatch))[0]
	return, systime(/sec) - global.job_status[match].last_run
end


;\\ Check to see if we need to email the current log (once per day)
pro sdi_monitor_log_manage

	common sdi_monitor_common, global, persistent

	logName = 'c:\rsi\idl\routines\sdi\monitor\Log\' + 'AnalysisLog_' + $
				dt_tm_fromjs(dt_tm_tojs(systime()), format='Y$_doy$') + '.txt'

	return

	if file_test(logName) eq 0 then begin
		if (systime(/sec) - global.log_email_sent_at)/3600. gt 24. then begin
			sdi_monitor_send_email, global.email_list, 'SDI Monitor Log', 'Log file is non-existent'
			global.log_email_sent_at = systime(/sec)
			return
		endif
	endif

	if (systime(/sec) - global.log_email_sent_at)/3600. gt 24. then begin
		if file_lines(logName) gt 0 then begin
			logtext = strarr(file_lines(logName))
			openr, hnd, logName, /get
			readf, hnd, logtext
			free_lun, hnd
		  	sdi_monitor_send_email, global.email_list, 'SDI Monitor Log', strjoin(logtext, string(13B), /single)
		endif else begin
			sdi_monitor_send_email, global.email_list, 'SDI Monitor Log', 'Log file is empty'
		endelse
		global.log_email_sent_at = systime(/sec)
	endif
end

pro sdi_monitor_send_email, addresses, subject, body

	common sdi_monitor_common, global, persistent

	for k = 0, n_elements(addresses) - 1 do begin
  		cmd = 'cd ' + global.home_dir + ' &'
    	cmd += ' bmail.exe -s fuzz.gi.alaska.edu -t ' + addresses[k]
    	cmd += ' -f sdimonitor@gi.alaska.edu '
    	cmd += '-a "' + subject + '"'
    	cmd += ' -b "' + body + '"'
    	spawn, cmd, /nowait
  	endfor
end

pro sdi_monitor_event, event

	common sdi_monitor_common, global, persistent


	;\\ persistent = {snapshots:ptr([snapshot struc]), $
	;\\				  zonemaps:ptr([zonemap struc]), $
	;\\				  calibrations:ptr([snapshot struc]) }
	;\\ snapshots = {site id, spectra:ptr, fits:ptr, start/end, scans, site, wavelength, zonemap_index}
	;\\ zonemaps = {zmap id, zonemap, centers:ptr, rads:ptr, secs:ptr}
	;\\ calibrations = {site id, spectra:ptr, fits:ptr, start/end, scans, site, wavelength, zonemap_index}


	widget_control, get_uval = uval, event.id


	;\\ Widget events from uval-containing widgets
	if size(uval, /type) eq 8 then begin

		case uval.tag of

			'file_background': begin
				pick_base = widget_base(title = 'Select Background Parameter', /floating, group=global.base_id, col=1)
				list = ['Temperature', 'Intensity', 'SNR/Scan', 'Chi Squared']
				for j = 0, n_elements(list) - 1 do begin
					btn = widget_button(pick_base, value=list[j], uval={tag:'pick_background', $
										select:list[j], base:pick_base}, font='Ariel*15*Bold')
				endfor
				widget_control, /realize, pick_base
				xmanager, 'sdi_monitor', pick_base, event = 'sdi_monitor_event'
			end

			'file_jobs': begin
				pick_base = widget_base(title = 'Set Job Status', /floating, group=global.base_id, col=1, /nonexclusive)
				list = global.job_status.name
				for j = 0, n_elements(list) - 1 do begin
					btn = widget_button(pick_base, value=list[j], uval={tag:'toggle_job', $
										select:list[j], base:pick_base}, font='Ariel*15*Bold')
					widget_control, btn, set_button = global.job_status[j].active
				endfor
				widget_control, /realize, pick_base
				xmanager, 'sdi_monitor', pick_base, event = 'sdi_monitor_event'
			end

			'pick_background': begin
				global.background_parameter = uval.select
				widget_control, /destroy, uval.base
			end

   			'toggle_job': begin
				widget_control, get_uval = uval, event.id
				match = (where(global.job_status.name eq uval.select, nmatch))[0]
				global.job_status[match].active = event.select

				monitor_jobs = where(global.job_status.active eq 1, njobs)
				if (njobs gt 0) then begin
					monitor_jobs_label = string(njobs, f='(i0)') + string([13b,10b]) + $
										 strjoin('     ' + global.job_status[monitor_jobs].name, string([13b,10b]))
				endif else begin
					monitor_jobs_label = 'None'
				endelse
				id = widget_info(global.base_id, find = 'status_jobs_running')
				widget_control, set_value = 'Monitor Jobs Running: ' + monitor_jobs_label , ysize = 15*(njobs+1), id
			end

			else:
		endcase

		return
	endif


	;\\ Base widget resize event
	if tag_names(event, /structure_name) eq 'WIDGET_BASE' then begin

	endif

	if tag_names(event, /structure_name) eq 'WIDGET_TIMER' then begin

		;\\ Queue next timer event
			widget_control, timer = global.timer_interval, global.base_id

		;\\ Manage the log (check if we need to open a new one, email the current one, etc)
			sdi_monitor_log_manage

		;\\ Check for watchdog script
			;watchdog_file = global.home_dir + '\watchdog\monitor_crash_file.tmp
			;if file_test(watchdog_file) eq 1 then file_delete, watchdog_file, /quiet

		;\\ Read snapshot files in in_dir
			in_files = file_search(global.in_dir + '*snapshot*idlsave', count = n_in, /test_regular)
			if n_in eq 0 then goto, MONITOR_FILE_LOOP_END

		;\\ Only take the ones that are more than N seconds old, to (try to) prevent read errors
			file_age = systime(/sec) - (file_info(in_files)).mtime
			keep = where(file_age gt global.min_file_age, n_keep)

			if n_keep gt 0 then begin
				in_files = in_files[keep]
				n_in = n_keep
			endif else begin
				goto, MONITOR_FILE_LOOP_END
			endelse


			for k = 0, n_in - 1 do begin

				;\\ Handle read errors (these do occur)
				catch, error_status
				if error_status ne 0 then begin
					print, 'Error index: ', error_status
					print, 'Error message: ', !ERROR_STATE.MSG
					catch, /cancel
					continue
				endif

				restore, in_files[k]
				catch, /cancel

				;\\ Build up unique id's for this snapshot site, wavelength, and zonemap type
					site_lambda_id = strupcase(snapshot.site_code) + '_' + $
						 			 string(snapshot.wavelength, f='(i04)')
					zmap_type_id = strjoin(string(snapshot.rads*100, f='(i0)')) + '_' + $
						 		   strjoin(string(snapshot.secs, f='(i0)'))

					have_zmap_type = -1
					have_site_lambda = -1
					is_new_snapshot = 0


				;\\ Do we have previous data for this zonemap type?
					if ptr_valid(persistent.zonemaps) ne 0 then begin
						ids = (*persistent.zonemaps).id
						match = where(strmatch(ids, zmap_type_id) eq 1, n_matching)
						if n_matching eq 1 then have_zmap_type = match[0]
					endif


				;\\ If we have the zmap type, do we have site and lambda?
					if have_zmap_type ne -1 then begin
						ids = (*persistent.snapshots).id
						match = where(strmatch(ids, site_lambda_id) eq 1 and $
								  	  (*persistent.snapshots).zonemap_index eq have_zmap_type, n_matching)
						if n_matching eq 1 then have_site_lambda = match[0]
					endif


				;\\ If we have both zmap type and site lambda, is this a new snapshot?
					if have_zmap_type ne -1 and have_site_lambda ne -1 then begin
						curr_snapshot = (*persistent.snapshots)[have_site_lambda]
						if curr_snapshot.start_time ne snapshot.start_time and $
						   curr_snapshot.end_time ne snapshot.end_time then is_new_snapshot = 1
					endif


				;\\ If the snapshot is not a new one, we are done with this file
					if have_zmap_type ne -1 and $
					   have_site_lambda ne -1 and $
					   is_new_snapshot eq 0 then continue


				;\\ If this is a new zonemap type, make the zonemap, get zone centers, and add entry
					if have_zmap_type eq -1 then begin
						zonemap = zonemapper(global.zmap_size, global.zmap_size, $
											[global.zmap_size, global.zmap_size]/2., $
											 snapshot.rads, snapshot.secs, 0)
						zone_centers = get_zone_centers(zonemap)

						pix_per_zone = pixels_per_zone( 0, /relative, zonemap=zonemap)

						zmap_entry = {id:zmap_type_id, $
									  zonemap:zonemap, $
									  centers:ptr_new(zone_centers), $
									  rads:ptr_new(snapshot.rads), $
									  secs:ptr_new(snapshot.secs), $
									  pix_per_zone:ptr_new(pix_per_zone) }

						if ptr_valid(persistent.zonemaps) eq 0 then begin
							persistent.zonemaps = ptr_new([zmap_entry])
						endif else begin
							*persistent.zonemaps = [*persistent.zonemaps, zmap_entry]
						endelse
						have_zmap_type = n_elements(*persistent.zonemaps) - 1
					endif


				;\\ Create the new snapshot data entry
					snapshot_entry = {id:site_lambda_id, $
									  zonemap_index:have_zmap_type, $
									  spectra:ptr_new(snapshot.spectra), $
									  fits:ptr_new(), $
									  start_time:snapshot.start_time, $
								 	  end_time:snapshot.end_time, $
									  scans:snapshot.scans, $
									  scan_channels:snapshot.scan_channels, $
									  nzones:snapshot.nzones, $
									  wavelength:snapshot.wavelength, $
							  		  site_code:snapshot.site_code }

					*global.latest_snapshot = snapshot_entry

					if snapshot.wavelength eq 6328 then begin
						calibration_entry = {id:site_lambda_id, $
										  	 zonemap_index:have_zmap_type, $
										  	 spectra:ptr_new(snapshot.spectra), $
										  	 fits:ptr_new(), $
										  	 start_time:snapshot.start_time, $
									 	   	 end_time:snapshot.end_time, $
										  	 scans:snapshot.scans, $
										  	 scan_channels:snapshot.scan_channels, $
										  	 nzones:snapshot.nzones, $
										  	 wavelength:snapshot.wavelength, $
								  		  	 site_code:snapshot.site_code }
					endif

				;\\ If we dont have site and lambda, append to the snapshots array
					if have_zmap_type ne -1 and have_site_lambda eq -1 then begin
						if ptr_valid(persistent.snapshots) eq 0 then begin
							persistent.snapshots = ptr_new([snapshot_entry])
						endif else begin
							*persistent.snapshots = [*persistent.snapshots, snapshot_entry]
						endelse

						;\\ If it is a calibration wavelength, put it in the calibrations tag as well
						if snapshot.wavelength eq 6328 then begin
							if ptr_valid(persistent.calibrations) eq 0 then begin
								persistent.calibrations = ptr_new([calibration_entry])
							endif else begin
								*persistent.calibrations = [*persistent.calibrations, calibration_entry]
							endelse
						endif
					endif


				;\\ If we do have site and lambda, replace the existing info with new snapshot
					if have_zmap_type ne -1 and have_site_lambda ne -1 then begin
						;\\ Free the pointer to the previous spectra and fits
						ptr_free, (*persistent.snapshots)[have_site_lambda].spectra
						ptr_free, (*persistent.snapshots)[have_site_lambda].fits
						(*persistent.snapshots)[have_site_lambda] = snapshot_entry

						;\\ If it is a calibration wavelength, check to see if it is the first one for the night
						if snapshot.wavelength eq 6328 then begin

							if ptr_valid(persistent.calibrations) eq 0 then begin
								persistent.calibrations = ptr_new([calibration_entry])
							endif else begin
								match = where((*persistent.calibrations).site_code eq snapshot_entry.site_code and $
											  (*persistent.calibrations).zonemap_index eq have_zmap_type, n_match)
								if n_match eq 1 then begin
									idx = match[0]
									if (snapshot.start_time - curr_snapshot.start_time) gt 4*3600. then begin
										ptr_free, (*persistent.calibrations)[idx].spectra
										ptr_free, (*persistent.calibrations)[idx].fits
										(*persistent.calibrations)[idx] = calibration_entry
									endif
								endif ;\\ match = 1
							endelse ;\\ have cals
						endif ;\\ snapshot is laser
					endif ;\\ have zmap and lambda for site


				;\\ Save the current persistent data
					log_emailed = global.log_emailed
					save, filename = global.persistent_file, persistent, log_emailed
			endfor


	MONITOR_FILE_LOOP_END:

		;\\ Check to see if any of the snapshots need spectral fits
		if size(persistent, /type) eq 0 then return
		if ptr_valid(persistent.snapshots) eq 0 then return
		if ptr_valid(persistent.calibrations) eq 0 then return

		;\\ First look for any calibrations that need fitting (why fit them?)
		calibrations = *persistent.calibrations
		fit_these = where(ptr_valid(calibrations.fits) eq 0 and $
						  calibrations.wavelength eq 6328, n_fit)

		for k = 0, n_fit - 1 do begin
			fits = sdi_monitor_fitspex(calibrations[fit_these[k]], calibrations[fit_these[k]], /calibration)
			ptr_free, (*persistent.calibrations)[fit_these[k]].fits  ;\\ this should be redundant
			(*persistent.calibrations)[fit_these[k]].fits = ptr_new(fits)
		endfor

		;\\ Now fit the snapshots
		snapshots = *persistent.snapshots
		fit_these = where(ptr_valid(snapshots.fits) eq 0 and $
						  snapshots.wavelength ne 6328 and $
						  snapshots.wavelength ne 5435, n_fit)

		for k = 0, n_fit - 1 do begin

			;\\ Find the corresponding instrument profiles for this snapshot (if we have them)
			ip_id = strupcase(snapshots[fit_these[k]].site_code) + '_6328'
			match = where(calibrations.id eq ip_id and $
						  calibrations.zonemap_index eq snapshots[fit_these[k]].zonemap_index, n_matching)

			if n_matching eq 1 then begin
				ip_snapshot = calibrations[match[0]]
				fits = sdi_monitor_fitspex(snapshots[fit_these[k]], ip_snapshot)
				ptr_free, (*persistent.snapshots)[fit_these[k]].fits
				(*persistent.snapshots)[fit_these[k]].fits = ptr_new(fits)

				;\\ Once they have been fit, new snapshots can be added to the timeseries
					save_name = global.home_dir + '\Timeseries\' + snapshots[fit_these[k]].id + '_timeseries.idlsave'
					if file_test(save_name) eq 1 then begin
						restore, save_name
						restored = 1
					endif else begin
						restored = 0
					endelse

					snap = (*persistent.snapshots)[fit_these[k]]
					zone_dims = snap.nzones
					chann_dims = snap.scan_channels

					new_entry = {spectra:*snap.spectra, $
								 fits:*snap.fits, $
								 winds:{zonal:fltarr(zone_dims), $
								 		merid:fltarr(zone_dims)}, $
								 start_time:snap.start_time, $
								 end_time:snap.end_time, $
								 scans:snap.scans }

					if restored eq 0 then begin
						series = new_entry
						zmap = (*persistent.zonemaps)[snap.zonemap_index]
						zonemap_info = {zonemap:zmap.zonemap, $
										centers:*zmap.centers, $
										rads:*zmap.rads, $
										secs:*zmap.secs }
						meta = {zonemap_info:zonemap_info, $
								scan_channels:snap.scan_channels, $
								wavelength:snap.wavelength, $
								site_code:snap.site_code, $
								gap_mm:(*snap.fits).gap_mm}
					endif else begin
						series = [series, new_entry]

						if size(meta, /type) eq 0 then begin
							zmap = (*persistent.zonemaps)[snap.zonemap_index]
							zonemap_info = {zonemap:zmap.zonemap, $
											centers:*zmap.centers, $
											rads:*zmap.rads, $
											secs:*zmap.secs }
							meta = {zonemap_info:zonemap_info, $
									scan_channels:snap.scan_channels, $
									wavelength:snap.wavelength, $
									site_code:snap.site_code, $
									gap_mm:(*snap.fits).gap_mm}
						endif
					endelse

					if n_elements(series) gt global.max_timeseries_length then begin
						series = series[global.timeseries_chop:*]
					endif
					print, systime(/ut), save_name
					save, filename = save_name, series, meta

				;endif ;\\ matching wavelengths for time series
			endif ;\\ found insprofs
		endfor ;\\ loop over snapshots

		log_emailed = global.log_emailed
		save, filename = global.persistent_file, persistent, log_emailed

		ftp = 0
		image_names = 0
		draw_ids = ''

		;\\ Update the GUI info
		list = ['Current UT: ' + systime(/ut)]
		list = [list, '']
		if size(*global.latest_snapshot, /type) ne 0 then begin
			lsnap = *global.latest_snapshot
			list = [list, 'Latest Snapshot: ']
			list = [list, 'Site: ' + lsnap.site_code]
			list = [list, 'Wavelength: ' + string(lsnap.wavelength/10., f='(f0.1)') + 'nm']
			list = [list, 'Date: ' + dt_tm_fromjs(lsnap.start_time, format='0d$/0n$/Y$')]
			list = [list, 'Start Time: ' + dt_tm_fromjs(lsnap.start_time, format='h$:m$:s$')]
			list = [list, 'Stop Time: ' + dt_tm_fromjs(lsnap.end_time, format='h$:m$:s$')]
			list = [list, 'Exp Time: ' + string((lsnap.end_time - lsnap.start_time)/60., f='(f0.1)') + ' mins']
			list = [list, 'Scans: ' + string(lsnap.scans, f='(i0)')]
			list = [list, 'Zones: ' + string(lsnap.nzones, f='(i0)')]
			list = [list, 'SiteID: ' + lsnap.id]
			if ptr_valid(lsnap.fits) then fitted = 'yes' else fitted = 'no'
			list = [list, 'Fitted?: ' + fitted]
			list = [list, '']
		endif

		flist = file_search(global.home_dir + '\Plots\*.png', count = nf)
		len = string(max(strlen(file_basename(flist))), f='(i0)')
		list = [list, 'Plot File:' + strjoin(replicate(' ', 1+len-10), '') + 'Age (minutes):']
		for ii = 0, nf - 1 do begin
			info = file_info(flist[ii])
			name = file_basename(info.name)
			list = [list, name + strjoin(replicate(' ', 1+len-strlen(name)), '') + ': ' $
					+ string((systime(/sec) - info.mtime)/60., f='(f0.1)')]
		endfor

		widget_control, set_value=list, global.list_id

	endif ;\\ widget timer events

	heap_gc
end



;\\ Cleanup
pro sdi_monitor_cleanup, arg

	common sdi_monitor_common, global, persistent

	persistent = 0
	heap_gc, /ptr, /verbose
	print, ptr_valid()
end


;\\ Main routine
pro sdi_monitor

	common sdi_monitor_common, global, persistent

	in_dir = 'C:\FTP\'
	whoami, home_dir, file
	out_dir = home_dir

	;\\ Recipient list for email updates
	email_list = ['callumenator@gmail.com', $
				  'mark.conde@gi.alaska.edu']


	;\\ Control which jobs will be run
	job_status = [{name:'snapshots', active:1, last_run:0D}, $
				  {name:'timeseries', active:1, last_run:0D}, $
				  {name:'windfields', active:1, last_run:0D}, $
				  {name:'multistatic', active:1, last_run:0D} ]

	zmap_size = 200.
	min_file_age = 5 ;\\ age in seconds
	timer_interval = 2
	max_timeseries_length = 1500 ;\\ number of exposures to keep in timeseries save files
	timeseries_chop = 100 ;\\ how many of the oldest exposures are chopped off the timeseries when it gets full
	oldest_snapshot = 10 ;\\ in days, snapshots older than this are greyed out

	;\\ Restore persistent data if any
		persistent_file = home_dir + 'persistent.idlsave'
		if file_test(persistent_file) then begin
			restore, persistent_file
		endif else begin
			persistent = {snapshots:ptr_new(), $
					  	  zonemaps:ptr_new(), $
					  	  calibrations:ptr_new()}
			log_emailed = ''
		endelse

	font = 'Consolas*18'
	base = widget_base(col = 1, title='SDI Monitor', /TLB_SIZE_EVENTS, mbar=menu )
	list = widget_list(base, font=font, xs = 50, ys=30)

	widget_control, /realize, base
	widget_control, timer = timer_interval, base

	global = {persistent_file:persistent_file, $
			  in_dir:in_dir, $
			  out_dir:out_dir, $
			  home_dir:home_dir, $
			  zmap_size:zmap_size, $
			  min_file_age:min_file_age, $
			  max_timeseries_length:max_timeseries_length, $
			  timeseries_chop:timeseries_chop, $
			  timer_interval:timer_interval, $
			  oldest_snapshot:oldest_snapshot, $
			  base_id:base, $
			  list_id:list, $
			  font:font, $
			  job_status:job_status, $
			  email_list:email_list, $
			  log_emailed:log_emailed, $
			  latest_snapshot:ptr_new()}

	global.latest_snapshot = ptr_new(/alloc)

	xmanager, 'sdi_monitor', base, event = 'sdi_monitor_event', $
			  cleanup = 'sdi_monitor_cleanup', /no_block
end
