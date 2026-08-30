# Replaces the stock nice!view peripheral art (balloon/mountain) with
# held_ether. Only compiled for the peripheral half, matching the
# upstream nice_view CMakeLists condition.
if(CONFIG_SILAKKA54_CUSTOM_ART AND CONFIG_ZMK_DISPLAY AND CONFIG_NICE_VIEW_WIDGET_STATUS)
  if(CONFIG_ZMK_SPLIT AND NOT CONFIG_ZMK_SPLIT_ROLE_CENTRAL)
    zephyr_library()
    zephyr_library_sources(src/held_ether_art.c)
  endif()
endif()
