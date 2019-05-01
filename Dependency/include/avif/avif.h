// Copyright 2019 Joe Drago. All rights reserved.
// SPDX-License-Identifier: BSD-2-Clause

#ifndef AVIF_AVIF_H
#define AVIF_AVIF_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// ---------------------------------------------------------------------------
// Constants

#define AVIF_VERSION_MAJOR 0
#define AVIF_VERSION_MINOR 1
#define AVIF_VERSION_PATCH 3
#define AVIF_VERSION (AVIF_VERSION_MAJOR * 10000) + (AVIF_VERSION_MINOR * 100) + AVIF_VERSION_PATCH

typedef int avifBool;
#define AVIF_TRUE 1
#define AVIF_FALSE 0

#define AVIF_LOSSLESS 0
#define AVIF_BEST_QUALITY 0
#define AVIF_WORST_QUALITY 63

#define AVIF_PLANE_COUNT_RGB 3
#define AVIF_PLANE_COUNT_YUV 3

enum avifPlanesFlags
{
    AVIF_PLANES_RGB = (1 << 0),
    AVIF_PLANES_YUV = (1 << 1),
    AVIF_PLANES_A   = (1 << 2),

    AVIF_PLANES_ALL = 0xff
};

enum avifChannelIndex
{
    // rgbPlanes
    AVIF_CHAN_R = 0,
    AVIF_CHAN_G = 1,
    AVIF_CHAN_B = 2,

    // yuvPlanes - These are always correct, even if UV is flipped when encoded (YV12)
    AVIF_CHAN_Y = 0,
    AVIF_CHAN_U = 1,
    AVIF_CHAN_V = 2
};

// ---------------------------------------------------------------------------
// Utils

const char * avifVersion(void);

// Yes, clamp macros are nasty. Do not use them.
#define AVIF_CLAMP(x, low, high)  (((x) > (high)) ? (high) : (((x) < (low)) ? (low) : (x)))

float avifRoundf(float v);

uint16_t avifHTONS(uint16_t s);
uint16_t avifNTOHS(uint16_t s);
uint32_t avifHTONL(uint32_t l);
uint32_t avifNTOHL(uint32_t l);

// ---------------------------------------------------------------------------
// Memory management

void * avifAlloc(size_t size);
void avifFree(void * p);

// ---------------------------------------------------------------------------
// avifResult

typedef enum avifResult
{
    AVIF_RESULT_OK = 0,
    AVIF_RESULT_UNKNOWN_ERROR,
    AVIF_RESULT_INVALID_FTYP,
    AVIF_RESULT_NO_CONTENT,
    AVIF_RESULT_NO_YUV_FORMAT_SELECTED,
    AVIF_RESULT_REFORMAT_FAILED,
    AVIF_RESULT_UNSUPPORTED_DEPTH,
    AVIF_RESULT_ENCODE_COLOR_FAILED,
    AVIF_RESULT_ENCODE_ALPHA_FAILED,
    AVIF_RESULT_BMFF_PARSE_FAILED,
    AVIF_RESULT_NO_AV1_ITEMS_FOUND,
    AVIF_RESULT_DECODE_COLOR_FAILED,
    AVIF_RESULT_DECODE_ALPHA_FAILED,
    AVIF_RESULT_COLOR_ALPHA_SIZE_MISMATCH,
    AVIF_RESULT_ISPE_SIZE_MISMATCH,
    AVIF_UNSUPPORTED_PIXEL_FORMAT
} avifResult;

const char * avifResultToString(avifResult result);

// ---------------------------------------------------------------------------
// avifRawData: Generic raw memory storage

// Note: you can use this struct directly (without the functions) if you're
// passing data into avif*() functions, but you should use avifRawDataFree()
// if any avif*() function populates one of these.

typedef struct avifRawData
{
    uint8_t * data;
    size_t size;
} avifRawData;

// Initialize avifRawData on the stack with this
#define AVIF_RAW_DATA_EMPTY { NULL, 0 }

void avifRawDataRealloc(avifRawData * raw, size_t newSize);
void avifRawDataSet(avifRawData * raw, const uint8_t * data, size_t len);
void avifRawDataConcat(avifRawData * dst, avifRawData ** srcs, int srcsCount);
void avifRawDataFree(avifRawData * raw);

// ---------------------------------------------------------------------------
// avifPixelFormat

typedef enum avifPixelFormat
{
    // No pixels are present
    AVIF_PIXEL_FORMAT_NONE = 0,

    AVIF_PIXEL_FORMAT_YUV444,
    AVIF_PIXEL_FORMAT_YUV422,
    AVIF_PIXEL_FORMAT_YUV420,
    AVIF_PIXEL_FORMAT_YV12
} avifPixelFormat;

typedef struct avifPixelFormatInfo
{
    int chromaShiftX;
    int chromaShiftY;
    int aomIndexU; // maps U plane to AOM-side plane index
    int aomIndexV; // maps V plane to AOM-side plane index
} avifPixelFormatInfo;

void avifGetPixelFormatInfo(avifPixelFormat format, avifPixelFormatInfo * info);

// ---------------------------------------------------------------------------
// avifNclxColorProfile

typedef enum avifNclxColourPrimaries
{
    // This is actually reserved, but libavif uses it as a sentinel value.
    AVIF_NCLX_COLOUR_PRIMARIES_UNKNOWN = 0,

    AVIF_NCLX_COLOUR_PRIMARIES_BT709 = 1,
    AVIF_NCLX_COLOUR_PRIMARIES_BT1361_0 = 1,
    AVIF_NCLX_COLOUR_PRIMARIES_IEC61966_2_1 = 1,
    AVIF_NCLX_COLOUR_PRIMARIES_SRGB = 1,
    AVIF_NCLX_COLOUR_PRIMARIES_SYCC = 1,
    AVIF_NCLX_COLOUR_PRIMARIES_IEC61966_2_4 = 1,
    AVIF_NCLX_COLOUR_PRIMARIES_UNSPECIFIED = 2,
    AVIF_NCLX_COLOUR_PRIMARIES_BT470_6M = 4,
    AVIF_NCLX_COLOUR_PRIMARIES_BT601_7_625 = 5,
    AVIF_NCLX_COLOUR_PRIMARIES_BT470_6G = 5,
    AVIF_NCLX_COLOUR_PRIMARIES_BT601_7_525 = 6,
    AVIF_NCLX_COLOUR_PRIMARIES_BT1358 = 6,
    AVIF_NCLX_COLOUR_PRIMARIES_ST240 = 7,
    AVIF_NCLX_COLOUR_PRIMARIES_GENERIC_FILM = 8,
    AVIF_NCLX_COLOUR_PRIMARIES_BT2020 = 9,
    AVIF_NCLX_COLOUR_PRIMARIES_BT2100 = 9,
    AVIF_NCLX_COLOUR_PRIMARIES_XYZ = 10,
    AVIF_NCLX_COLOUR_PRIMARIES_ST428 = 10,
    AVIF_NCLX_COLOUR_PRIMARIES_RP431_2 = 11,
    AVIF_NCLX_COLOUR_PRIMARIES_EG432_1 = 12,
    AVIF_NCLX_COLOUR_PRIMARIES_P3 = 12,
    AVIF_NCLX_COLOUR_PRIMARIES_EBU3213E = 22
} avifNclxColourPrimaries;

// outPrimaries: rX, rY, gX, gY, bX, bY, wX, wY
void avifNclxColourPrimariesGetValues(avifNclxColourPrimaries ancp, float outPrimaries[8]);
avifNclxColourPrimaries avifNclxColourPrimariesFind(float inPrimaries[8], const char ** outName);

typedef enum avifNclxTransferCharacteristics
{
    // This is actually reserved, but libavif uses it as a sentinel value.
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_UNKNOWN = 0,

    AVIF_NCLX_TRANSFER_CHARACTERISTICS_BT709 = 1,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_BT1361 = 1,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_UNSPECIFIED = 2,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_GAMMA22 = 4,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_GAMMA28 = 5,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_BT601 = 6,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_ST240 = 7,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_LINEAR = 8,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_LOG_100_1 = 9,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_LOG_100_SQRT = 10,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_IEC61966 = 11,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_BT1361_EXTENDED = 12,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_61966_2_1 = 13,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_SRGB = 13,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_SYCC = 13,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_BT2020_10BIT = 14,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_BT2020_12BIT = 15,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_ST2084 = 16,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_BT2100_PQ = 16,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_ST428 = 17,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_STD_B67 = 18,
    AVIF_NCLX_TRANSFER_CHARACTERISTICS_BT2100_HLG = 18
} avifNclxTransferCharacteristics;

typedef enum avifNclxMatrixCoefficients
{
    AVIF_NCLX_MATRIX_COEFFICIENTS_IDENTITY = 0,
    AVIF_NCLX_MATRIX_COEFFICIENTS_BT709 = 1,
    AVIF_NCLX_MATRIX_COEFFICIENTS_BT1361_0 = 1,
    AVIF_NCLX_MATRIX_COEFFICIENTS_SRGB = 1,
    AVIF_NCLX_MATRIX_COEFFICIENTS_SYCC = 1,
    AVIF_NCLX_MATRIX_COEFFICIENTS_UNSPECIFIED = 2,
    AVIF_NCLX_MATRIX_COEFFICIENTS_USFC_73682 = 4,
    AVIF_NCLX_MATRIX_COEFFICIENTS_BT470_6B = 5,
    AVIF_NCLX_MATRIX_COEFFICIENTS_BT601_7_625 = 5,
    AVIF_NCLX_MATRIX_COEFFICIENTS_BT601_7_525 = 6,
    AVIF_NCLX_MATRIX_COEFFICIENTS_BT1700_NTSC = 6,
    AVIF_NCLX_MATRIX_COEFFICIENTS_ST170 = 6,
    AVIF_NCLX_MATRIX_COEFFICIENTS_ST240 = 7,
    AVIF_NCLX_MATRIX_COEFFICIENTS_BT2020_NCL = 9,
    AVIF_NCLX_MATRIX_COEFFICIENTS_BT2100 = 9,
    AVIF_NCLX_MATRIX_COEFFICIENTS_BT2020_CL = 10,
    AVIF_NCLX_MATRIX_COEFFICIENTS_ST2085 = 11,
    AVIF_NCLX_MATRIX_COEFFICIENTS_CHROMA_DERIVED_NCL = 12,
    AVIF_NCLX_MATRIX_COEFFICIENTS_CHROMA_DERIVED_CL = 13,
    AVIF_NCLX_MATRIX_COEFFICIENTS_ICTCP = 14
} avifNclxMatrixCoefficients;

// for fullRangeFlag
typedef enum avifNclxRangeFlag
{
    AVIF_NCLX_LIMITED_RANGE = 0,
    AVIF_NCLX_FULL_RANGE = 0x80
} avifNclxRangeFlag;

typedef struct avifNclxColorProfile
{
    uint16_t colourPrimaries;
    uint16_t transferCharacteristics;
    uint16_t matrixCoefficients;
    uint8_t fullRangeFlag;
} avifNclxColorProfile;

// ---------------------------------------------------------------------------
// avifRange

typedef enum avifRange
{
    AVIF_RANGE_LIMITED = 0,
    AVIF_RANGE_FULL,
} avifRange;

// ---------------------------------------------------------------------------
// avifProfileFormat

typedef enum avifProfileFormat
{
    // No color profile present
    AVIF_PROFILE_FORMAT_NONE = 0,

    // icc represents an ICC profile chunk (inside a colr box)
    AVIF_PROFILE_FORMAT_ICC,

    // nclx represents a valid nclx colr box
    AVIF_PROFILE_FORMAT_NCLX
} avifProfileFormat;

// ---------------------------------------------------------------------------
// avifImage

typedef struct avifImage
{
    // Image information
    int width;
    int height;
    int depth; // all planes (RGB/YUV/A) must share this depth; if depth>8, all planes are uint16_t internally

    uint8_t * rgbPlanes[AVIF_PLANE_COUNT_RGB];
    uint32_t rgbRowBytes[AVIF_PLANE_COUNT_RGB];

    avifPixelFormat yuvFormat;
    avifRange yuvRange;
    uint8_t * yuvPlanes[AVIF_PLANE_COUNT_YUV];
    uint32_t yuvRowBytes[AVIF_PLANE_COUNT_YUV];

    uint8_t * alphaPlane;
    uint32_t alphaRowBytes;

    // Profile information
    avifProfileFormat profileFormat;
    avifRawData icc;
    avifNclxColorProfile nclx;

    // Useful stats from the most recent read/write
    struct IOStats
    {
        size_t colorOBUSize;
        size_t alphaOBUSize;
    } ioStats;
} avifImage;

avifImage * avifImageCreate(int width, int height, int depth, avifPixelFormat yuvFormat);
avifImage * avifImageCreateEmpty(void); // helper for making an image to decode into
void avifImageDestroy(avifImage * image);

void avifImageSetProfileNone(avifImage * image);
void avifImageSetProfileICC(avifImage * image, uint8_t * icc, size_t iccSize);
void avifImageSetProfileNCLX(avifImage * image, avifNclxColorProfile * nclx);

void avifImageAllocatePlanes(avifImage * image, uint32_t planes); // Ignores any pre-existing planes
void avifImageFreePlanes(avifImage * image, uint32_t planes);     // Ignores already-freed planes
avifResult avifImageRead(avifImage * image, avifRawData * input);

// avifImageWrite notes:
// * if returns AVIF_RESULT_OK, output must be freed with avifRawDataFree()
// * if (numThreads < 2), multithreading is disabled
// * quality range: [AVIF_BEST_QUALITY - AVIF_WORST_QUALITY]
avifResult avifImageWrite(avifImage * image, avifRawData * output, int numThreads, int quality);

// Used by avifImageRead/avifImageWrite
avifResult avifImageRGBToYUV(avifImage * image);
avifResult avifImageYUVToRGB(avifImage * image);

// Helpers
avifBool avifImageUsesU16(avifImage * image);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // ifndef AVIF_AVIF_H
