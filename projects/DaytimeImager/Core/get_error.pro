;\\ Code formatted by DocGen


;\D\<Function/method/pro documentation here>
function Get_Error, err_code  ;\A\<Arg0>

case err_code of

	0: error = 'PROGRAM FAILURE'
	1: error = 'PROGRAM SUCCESS'

	20001: error = 'DRV_ERROR_CODES'
	20002: error = 'DRV_SUCCESS'
	20003: error = 'DRV_VXDNOTINSTALLED'
	20004: error = 'DRV_ERROR_SCAN'
	20005: error = 'DRV_ERROR_CHECK_SUM'
	20006: error = 'DRV_ERROR_FILELOAD'
	20007: error = 'DRV_UNKNOWN_FUNCTION'
	20008: error = 'DRV_ERROR_VXD_INIT'
	20009: error = 'DRV_ERROR_ADDRESS'
	20010: error = 'DRV_ERROR_PAGELOCK'
	20011: error = 'DRV_ERROR_PAGEUNLOCK'
	20012: error = 'DRV_ERROR_BOARDTEST'
	20013: error = 'DRV_ERROR_ACK'
	20014: error = 'DRV_ERROR_UP_FIFO'
	20015: error = 'DRV_ERROR_PATTERN'
	20017: error = 'DRV_ACQUISITION_ERRORS'
	20018: error = 'DRV_ACQ_BUFFER'
	20019: error = 'DRV_ACQ_DOWNFIFO_FULL'
	20020: error = 'DRV_PROC_UNKNOWN_INSTRUCTION'
	20021: error = 'DRV_ILLEGAL_OP_CODE'
	20022: error = 'DRV_KINETIC_TIME_NOT_MET'
	20023: error = 'DRV_ACCUM_TIME_NOT_MET'
	20024: error = 'DRV_NO_NEW_DATA'
	20026: error = 'DRV_SPOOLERROR'

	20033: error = 'DRV_TEMP_CODES'
	20034: error = 'DRV_TEMP_OFF'
	20035: error = 'DRV_TEMP_NOT_STABILIZED'
	20036: error = 'DRV_TEMP_STABILIZED'
	20037: error = 'DRV_TEMP_NOT_REACHED'
	20038: error = 'DRV_TEMP_OUT_RANGE'
	20039: error = 'DRV_TEMP_NOT_SUPPORTED'
	20040: error = 'DRV_TEMP_DRIFT'

	20049: error = 'DRV_GENERAL_ERRORS'
	20050: error = 'DRV_INVALID_AUX'
	20051: error = 'DRV_COF_NOTLOADED'
	20052: error = 'DRV_FPGAPROG'
	20053: error = 'DRV_FLEXERROR'
	20054: error = 'DRV_GPIBERROR'
	20064: error = 'DRV_DATATYPE'

	20065: error = 'DRV_DRIVER_ERRORS'
	20066: error = 'DRV_P1INVALID'
	20067: error = 'DRV_P2INVALID'
	20068: error = 'DRV_P3INVALID'
	20069: error = 'DRV_P4INVALID'
	20070: error = 'DRV_INIERROR'
	20071: error = 'DRV_COFERROR'
	20072: error = 'DRV_ACQUIRING'
	20073: error = 'DRV_IDLE'
	20074: error = 'DRV_TEMPCYCLE'
	20075: error = 'DRV_NOT_INITIALIZED'
	20076: error = 'DRV_P5INVALID'
	20077: error = 'DRV_P6INVALID'
	20078: error = 'DRV_INVALID_MODE'
	20079: error = 'DRV_INVALID_FILTER'
	20080: error = 'DRV_I2CERRORS'
	20081: error = 'DRV_I2CDEVNOTFOUND''
	20082: error = 'DRV_I2CTIMEOUT'
	20083: error = 'DRV_P7INVALID'
	20089: error = 'DRV_USBERROR'
	20090: error = 'DRV_IOCERROR'
	20091: error = 'DRV_NOT_SUPPORTED'

	else: error = 'UNKNOWN ERROR'

endcase

return, error

end
