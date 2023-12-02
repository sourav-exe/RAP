CLASS zcl_custom_entity_impl DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_custom_entity_impl IMPLEMENTATION.


  METHOD if_rap_query_provider~select.

    DATA: lt_vbak TYPE STANDARD TABLE OF zcustom_entity_test.


    CHECK io_request->is_data_requested( ).

    CASE io_request->get_entity_id( ).

      WHEN 'ZCUSTOM_ENTITY_TEST'.

        "get filter
        DATA(nv_filter_string) = io_request->get_filter(  )->get_as_sql_string( ).

        "Sorting
        DATA(nt_sort_elements) = io_request->get_sort_elements( ).
        DATA(lt_sort_criteria) = VALUE string_table( FOR sort_element IN nt_sort_elements
                                                   ( sort_element-element_name && COND #( WHEN sort_element-descending = abap_true THEN ' descending'
                                                                                          ELSE ' ascending' ) ) ).
        DATA(lv_sort_string)  = COND #( WHEN lt_sort_criteria IS  NOT INITIAL THEN concat_lines_of( table = lt_sort_criteria sep = ', ' )
                                        ELSE 'primary key'  ).

        "get paging->Indicates how much data is to be shown
        DATA(nv_page_size) = io_request->get_paging( )->get_page_size(  ).
        DATA(nv_max_rows) = COND #( WHEN nv_page_size = if_rap_query_paging=>page_size_unlimited THEN 0
                                    ELSE nv_page_size ).
        "get offset->indicates the next set of data records to be fetched
        DATA(nv_offset) = io_request->get_paging( )->get_offset(  ).

        SELECT
            vbeln,
            ernam,
            auart
         FROM zsales_order_rap
         WHERE (nv_filter_string)
         ORDER BY (lv_sort_string)
         INTO TABLE @lt_vbak
         OFFSET @nv_offset UP TO @nv_max_rows ROWS.


        TRY.
            io_response->set_data( it_data = lt_vbak ).

            "request count
            IF io_request->is_total_numb_of_rec_requested( ).
              "select count
              SELECT COUNT( * ) FROM zsales_order_rap
                                WHERE (nv_filter_string)
                                INTO @DATA(lv_count).
              "fill response
              io_response->set_total_number_of_records( lv_count ).
            ENDIF.
          CATCH cx_rap_query_response_set_twic.
        ENDTRY.
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
