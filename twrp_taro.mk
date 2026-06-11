#
# Copyright (C) 2023 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/QUALCOMM/taro

# Inherit from device.mk configuration
$(call inherit-product, $(DEVICE_PATH)/device.mk)

# Release name
PRODUCT_RELEASE_NAME := taro

## Device identifier
PRODUCT_DEVICE := taro
PRODUCT_NAME := twrp_taro
PRODUCT_BRAND := QUALCOMM
PRODUCT_MODEL := taro
PRODUCT_MANUFACTURER := QUALCOMM

