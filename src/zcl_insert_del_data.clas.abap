CLASS zcl_insert_del_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_insert_del_data IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

    DATA: lv_operation TYPE char3.

    CASE Lv_operation.

      WHEN 'INS'.
        DATA(lv_count) = 1.
        DATA(lv_records_to_be_created) = 40.
        DATA(lv_so_no) = '4039'.

        WHILE ( lv_count < lv_records_to_be_created ).
          INSERT INTO zsales_order_rap VALUES @( VALUE zsales_order_rap( vbeln = lv_so_no ernam = 'ROYS' auart = 'YNRO' netwr = 1000 waerk = 'INR' ) ).
          lv_so_no += 1.
          lv_count += 1.
        ENDWHILE.

      WHEN 'DEL'.
        lv_so_no = '4000'.
        DELETE FROM zsales_order_rap WHERE vbeln >= @lv_so_no.
        DELETE FROM zso_item_rap.
        DELETE FROM zsales_hd_draft.
        DELETE FROM zso_item_draft.
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
