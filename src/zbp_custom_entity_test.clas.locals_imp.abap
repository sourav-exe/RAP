CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.

    "Structure and internal table types for the internal table serving
    "as transactional buffers for the root  entities
    TYPES: BEGIN OF gty_buffer,
             instance TYPE zcustom_entity_test,
             cid      TYPE string,
             changed  TYPE abap_bool,
             deleted  TYPE abap_bool,
           END OF gty_buffer.
    TYPES gtt_buffer TYPE TABLE OF gty_buffer WITH DEFAULT KEY.

    CLASS-DATA:
         "Internal tables serving as transactional buffers for the root entities
         root_buffer  TYPE gtt_buffer.

    "Structure and internal table types to include the keys for buffer preparation methods
    TYPES: BEGIN OF root_keys,
             key_field TYPE zcustom_entity_test-vbeln,
           END OF root_keys,
           tt_root_keys TYPE TABLE OF root_keys WITH DEFAULT KEY.

    "Buffer preparation methods
    CLASS-METHODS: prep_root_buffer IMPORTING keys TYPE tt_root_keys.

ENDCLASS.

CLASS lcl_buffer IMPLEMENTATION.

  METHOD prep_root_buffer.

  ENDMETHOD.

ENDCLASS.




CLASS lhc_SalesOrder DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR SalesOrder RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE SalesOrder.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE SalesOrder.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE SalesOrder.

    METHODS read FOR READ
      IMPORTING keys FOR READ SalesOrder RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK SalesOrder.

ENDCLASS.

CLASS lhc_SalesOrder IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD create.
  ENDMETHOD.

  METHOD update.
  ENDMETHOD.

  METHOD delete.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZCUSTOM_ENTITY_TEST DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZCUSTOM_ENTITY_TEST IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
