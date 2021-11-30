FUNCTION ZTEST_RFC_ABAPGIT.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"----------------------------------------------------------------------
DATA : jobname TYPE tbtcjob-jobname VALUE 'ZRSRFCCHK',
       jobclass TYPE tbtcjob-jobclass VALUE 'A',
       jobcount TYPE tbtcjob-jobcount,
       lv_startdate LIKE sy-datum,
       lv_starttime LIKE sy-uzeit,
       authcknam TYPE tbtcjob-authcknam,
       lv_varname TYPE rsvar-variant,
       lwa_vardesc TYPE varid .

DATA: BEGIN OF gt_varid.
        INCLUDE STRUCTURE varid.
DATA: END OF gt_varid.

DATA: BEGIN OF gt_varit OCCURS 2.
        INCLUDE STRUCTURE varit.
DATA: END OF gt_varit.

DATA: BEGIN OF gt_rsparams OCCURS 0.
        INCLUDE STRUCTURE rsparams.
DATA: END OF gt_rsparams.

authcknam = sy-uname.

lv_startdate = sy-datum.
lv_starttime = sy-uzeit + 300.

CONCATENATE  'ABAP' lv_starttime INTO lv_varname.

lwa_vardesc-report = 'RSRFCCHK'.

* fill VARID structure - Variantenkatalog, variant description

gt_varid-mandt        = sy-mandt.
gt_varid-report       = lwa_vardesc-report.
gt_varid-variant      = lv_varname.
gt_varid-flag1        = space.
gt_varid-flag2        = space.
gt_varid-transport    = space.
gt_varid-environmnt   = 'A'.         "Variant for batch and online
gt_varid-protected    = space.
gt_varid-secu         = space.
gt_varid-version      = '1'.
gt_varid-ename        = sy-uname.
gt_varid-edat         = sy-datum.
gt_varid-etime        = sy-uzeit.
gt_varid-aename       = space.
gt_varid-aedat        = space.
gt_varid-aetime       = space.
gt_varid-mlangu       = sy-langu.

*.fill VARIT structure - Variantentexte; variant texts
gt_varit-mandt      = sy-mandt.
gt_varit-langu      = sy-langu.
gt_varit-report     = lwa_vardesc-report.
gt_varit-variant    = lv_varname.
gt_varit-vtext      = lv_varname.
APPEND gt_varit.

gt_rsparams-selname = 'SRFCDEST'.
gt_rsparams-kind    = 'S'.
gt_rsparams-sign    = 'I'.
gt_rsparams-option  = 'EQ'.
*gt_rsparams-low     = '1000'.
*gt_rsparams-high    = '3500'.
APPEND gt_rsparams.

gt_rsparams-selname = 'STYPE'.
gt_rsparams-kind    = 'S'.
gt_rsparams-sign    = 'I'.
gt_rsparams-option  = 'EQ'.
*gt_rsparams-low     = 'FERT'.
*gt_rsparams-high    = 'ROH'.
APPEND gt_rsparams.

*gt_rsparams-selname = 'S_DDATE'.
*gt_rsparams-kind    = 'S'.
*gt_rsparams-sign    = 'I'.
*gt_rsparams-option  = 'EQ'.
*gt_rsparams-low     = '12.02.2008'.
*gt_rsparams-high    = sy-datum.
*APPEND gt_rsparams.
*
* Create Variant
CALL FUNCTION 'RS_CREATE_VARIANT'
  EXPORTING
    curr_report               = gt_varid-report
    curr_variant              = gt_varid-variant
    vari_desc                 = gt_varid
  TABLES
    vari_contents             = gt_rsparams
    vari_text                 = gt_varit
  EXCEPTIONS
    illegal_report_or_variant = 1
    illegal_variantname       = 2
    not_authorized            = 3
    not_executed              = 4
    report_not_existent       = 5
    report_not_supplied       = 6
    variant_exists            = 7
    variant_locked            = 8
    OTHERS                    = 9.

IF sy-subrc <> 0.

ENDIF.

CALL FUNCTION 'JOB_OPEN'
  EXPORTING
    jobname          = jobname
    jobclass         = jobclass
  IMPORTING
    jobcount         = jobcount
  EXCEPTIONS
    cant_create_job  = 1
    invalid_job_data = 2
    jobname_missing  = 3
    OTHERS           = 4.

IF sy-subrc = 0.

  CALL FUNCTION 'JOB_SUBMIT'
    EXPORTING
      authcknam               = authcknam
      jobcount                = jobcount
      jobname                 = jobname
      report                  = 'RSRFCCHK'
      variant                 = 'VAR'
    EXCEPTIONS
      bad_priparams           = 1
      bad_xpgflags            = 2
      invalid_jobdata         = 3
      jobname_missing         = 4
      job_notex               = 5
      job_submit_failed       = 6
      lock_failed             = 7
      program_missing         = 8
      prog_abap_and_extpg_set = 9
      OTHERS                  = 10.

  IF sy-subrc = 0.

    CALL FUNCTION 'JOB_CLOSE'
      EXPORTING
        jobcount             = jobcount
        jobname              = jobname
        sdlstrtdt            = lv_startdate
        sdlstrttm            = lv_starttime
      EXCEPTIONS
        cant_start_immediate = 1
        invalid_startdate    = 2
        jobname_missing      = 3
        job_close_failed     = 4
        job_nosteps          = 5
        job_notex            = 6
        lock_failed          = 7
        invalid_target       = 8
        OTHERS               = 9.
    IF sy-subrc = 0.

      CALL FUNCTION 'RS_VARIANT_DELETE'
        EXPORTING
          report               = gt_varid-report
          variant              = gt_varid-variant
          flag_confirmscreen   = 'X'
          flag_delallclient    = 'X'
        EXCEPTIONS
          not_authorized       = 1
          not_executed         = 2
          no_report            = 3
          report_not_existent  = 4
          report_not_supplied  = 5
          variant_locked       = 6
          variant_not_existent = 7
          no_corr_insert       = 8
          variant_protected    = 9
          OTHERS               = 10.
      IF sy-subrc <> 0.
      ENDIF.

    ENDIF.

  ENDIF.

ENDIF.




ENDFUNCTION.
