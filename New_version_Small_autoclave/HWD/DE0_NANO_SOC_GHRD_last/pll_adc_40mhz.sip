set_global_assignment -entity "pll_adc_40mhz" -library "lib_pll_adc_40mhz" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll_adc_40mhz" -library "lib_pll_adc_40mhz" -name IP_TOOL_VERSION "15.0"
set_global_assignment -entity "pll_adc_40mhz" -library "lib_pll_adc_40mhz" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll_adc_40mhz" -name SPD_FILE [file join $::quartus(sip_path) "pll_adc_40mhz.spd"]

set_global_assignment -library "lib_pll_adc_40mhz" -name MISC_FILE [file join $::quartus(sip_path) "pll_adc_40mhz_sim/pll_adc_40mhz.vo"]
