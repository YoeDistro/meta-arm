require ts-arm-platforms.inc

EXTRA_OECMAKE:append:corstone1000 = " -DSMM_GATEWAY_MAX_UEFI_VARIABLES=60 \
    "

EXTRA_OECMAKE:append:fvp-base = " -DMM_COMM_BUFFER_ADDRESS="0x00000000 0x81000000" \
    -DMM_COMM_BUFFER_PAGE_COUNT="8" \
    "
