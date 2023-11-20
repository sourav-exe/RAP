CLASS zcreate_num_range_object DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
    class-METHODS: get_sales_order_num RETURNING VALUE(rv_sales_order_num) type char10.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCREATE_NUM_RANGE_OBJECT IMPLEMENTATION.


  METHOD get_sales_order_num.
        TRY.
            cl_numberrange_runtime=>number_get(
              EXPORTING
                nr_range_nr       = '01'
                object            = 'ZSO_NR'
              IMPORTING
                number            = DATA(number_range_key)
                returncode        = DATA(number_range_return_code)
                returned_quantity = DATA(number_range_returned_quantity) ).

            rv_sales_order_num = number_range_key - number_range_returned_quantity + 1 .
            CONDENSE rv_sales_order_num.
          CATCH cx_number_ranges .
        ENDTRY.
  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.

    DATA:
      lv_object   TYPE cl_numberrange_objects=>nr_attributes-object,
      lv_devclass TYPE cl_numberrange_objects=>nr_attributes-devclass,
      lv_corrnr   TYPE cl_numberrange_objects=>nr_attributes-corrnr,

      lt_interval TYPE cl_numberrange_intervals=>nr_interval,
      ls_interval TYPE cl_numberrange_intervals=>nr_nriv_line..

    lv_object   = 'ZSO_NR'.
    lv_devclass = 'ZRAP'.
    lv_corrnr   = 'TRLK900344'.

*   intervals
    ls_interval-nrrangenr  = '01'.
    ls_interval-fromnumber = '00002000'.
    ls_interval-tonumber   = '00005000'.
    ls_interval-procind    = 'I'.
    APPEND ls_interval TO lt_interval.

delete from zsales_order_rap.
delete from zso_item_rap.
delete from zsales_hd_draft.
delete from zso_item_draft.

    TRY.
        out->write(  |Creation Executed| ).


        cl_numberrange_objects=>create(
          EXPORTING
            attributes = VALUE #( object     = lv_object
                                  domlen     = 'ZVBELN'
                                  percentage = 10
                                  devclass   = lv_devclass
                                  corrnr     = lv_corrnr )
            obj_text   = VALUE #( object     = lv_object
                                  langu      = 'E'
                                  txt        = 'Create object'
                                  txtshort   = 'Create' )
          IMPORTING
            errors     = DATA(lt_errors)
            returncode = DATA(lv_returncode) ).

        out->write(  |CREATED| ).
        out->write(  lv_returncode ).

*   create intervals
        CALL METHOD cl_numberrange_intervals=>create
          EXPORTING
            interval  = lt_interval
            object    = lv_object
            subobject = ' '
          IMPORTING
            error     = DATA(lv_error1)
            error_inf = DATA(ls_error1)
            error_iv  = DATA(lt_error_iv1)
            warning   = DATA(lv_warning1).

        out->write(  lv_error1 ).

      CATCH cx_root.
        out->write(  |Error during Number Range Creation| ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
