package com.lumera.app.data.remote

import com.lumera.app.data.model.stremio.IntroSegmentResponse
import retrofit2.http.GET
import retrofit2.http.Url

interface StremioServerApi {
    @GET
    suspend fun startIntroDetection(@Url url: String): IntroSegmentResponse

    @GET
    suspend fun getIntroStatus(@Url url: String): IntroSegmentResponse
}
