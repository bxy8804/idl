;***********************************************************************
pro corrflux,file,rec,w0def=w0def,nosave=nosave,ffx=ffx,helpme=helpme, $
    stp=stp,dw=dw,noplot=noplot,ffl=ffl,nsm=nsm,ddw=ddw
common comxy,xcur,ycur,zerr
if not keyword_set(w0def) then w0def=6563.
if n_params(0) eq 0 then helpme=1
if n_elements(file) eq 0 then file='-1'
if strtrim(string(file),2) eq '-1' then helpme=1
hlp:
if keyword_set(helpme) then begin
   print,' '
   print,'* CORRFLUX - procedure to tweak up flux corrections, using correction'
   print,'*   generated by FUDGEFLUX.'
   print,'*'
   print,'*   Calling sequence: CORRFLUX,file,recs'
   print,'*      file: name of data file, 6 = ECHEL.DAT, -1 for this help message.'
   print,'*      recs: -1 for this help message'
   print,'*            an integer or an array of record numbers to be done interactively'
   print,'*            ''*'' for automatic correction of all'
   print,'*   KEYWORDS:
   print,'*      ffx:  name of .FFX file, 0 for FUDGE, containing correction factor'
   print,'*      ffl:  if set, use .FFL file rather than .FFX file
   print,'*      w0def: the wavelength of the plot region; default=',strtrim(w0def,2)
   print,'*      NOSAVE: set to see results without overwriting data file.'
   print,' '
   return
   endif
;
case 1 of
   n_elements(ffl) gt 0: begin
      ffx=file      
      if not ffile(ffx+'.ffl') then ffx=strtrim(ffl,2)
      if not ffile(ffx+'.ffl') then ffx='fudge'
      if not ffile(ffx+'.ffl') then begin
         print,' correction factor file ',ffx+'.FFL not found. Returning'
         return
         endif else wl=get_ffl(ffx)                  ;correction factor
      nl=n_elements(wl)
      fl=wl*0.
      ffl=1
      end
   else: begin
      if not keyword_set(ffx) then ffx=file
      if not ffile(ffx+'.ffx') then ffx='fudge'
      if not ffile(ffx+'.ffx') then begin
         print,' correction factor file ',ffx+'.FFX not found. Returning'
         return
      endif else fact0=get_ffx(ffx,w0)                  ;correction factor
      ffl=0
      end
   endcase
;
if n_elements(rec) eq 0 then $
      read,' enter record number, -1 for help,''*'' for all: ',rec
if ifstring(rec) eq 1 then begin   ;string passed
   if rec ne '*' then begin
      print,' CORRFLUX cannot accept ',rec, ' as a parameter'
      rec=-1
      endif else rec=indgen(999)          ;all records
   endif
if n_elements(rec) eq 1 then rec=intarr(1)+rec     ;convert to array
if rec(0) eq -1 then begin
   helpme=1
   goto,hlp
   endif
;
setxy
if n_elements(dw) eq 0 then dw=100.
if w0def gt 0. then !x.range=[w0def-dw,w0def+dw]
pt='!6 CORRFLUX : '+file+':'
!x.title='!6Angstroms'
!y.title=ytit(0)
nrec=n_elements(rec)
for i=0,nrec-1 do begin
   recno=rec(i)
   gdat,file,h,w,f,e,recno
   if w0def gt 0. then !x.range=[(w0def-dw)>w(0),(w0def+dw)<max(w)]
   if n_elements(h) eq 1 then goto,done
   !p.title=pt+strtrim(recno,2)+' '+strtrim(byte(h(100:139)>32b),2)
   if ffl then begin
      if n_elements(ddw) eq 0 then ddw=4
      if ddw lt 0 then ddw=4
      for ii=0,nl-1 do begin
         k=fix(xindex(w,wl(ii))+0.5)
         fl(ii)=total(f(k-ddw:k+ddw))/(w(k+ddw+1)-w(k-ddw))
         endfor
      cf=mean(fl)/fl  ;correction factor
      fact=interpol(cf,wl,w)
      k1=fix(xindex(w,wl(0))+0.5)
      k2=fix(xindex(w,wl(nl-1))+0.5)
      fact(0:k1-ddw>0)=1.
      fact(k2+ddw:*)=1.
      if n_elements(nsm) eq 0 then nsm=5
      if nsm le 0 then nsm=5
      if nsm gt 2 then fact=smooth(fact,nsm)
      endif else fact=interpol(fact0,w0,w) 
      fcor=f*fact
   if not keyword_set(noplot) then begin
      plot,w,f,psym=0
      if (i eq 0) and (!d.name eq 'X') then wshow
      oplot,w,fcor,psym=0,color=85
      endif
   if not keyword_set(NOSAVE) then kdat,file,h,w,fcor,e,rec(i) else print,' Data not saved'
   endfor
done:
if keyword_set(stp) then stop,'CORRFLUX>>>'
return
end