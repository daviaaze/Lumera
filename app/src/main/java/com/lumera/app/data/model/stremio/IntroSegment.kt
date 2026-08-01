package com.lumera.app.data.model.stremio

import com.google.gson.annotations.SerializedName

data class IntroSegmentResponse(
    @SerializedName("status") val status: String? = null,
    @SerializedName("infoHash") val infoHash: String? = null,
    @SerializedName("fileIdx") val fileIdx: Int? = null,
    @SerializedName("introStart") val introStart: Double? = null,
    @SerializedName("introEnd") val introEnd: Double? = null,
    @SerializedName("cached") val cached: Boolean? = null,
    @SerializedName("progress") val progress: Double? = null,
    @SerializedName("error") val error: String? = null
)
