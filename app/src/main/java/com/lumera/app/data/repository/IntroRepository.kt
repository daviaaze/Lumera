package com.lumera.app.data.repository

import com.lumera.app.data.model.introdb.IntroDbSegmentsResponse
import com.lumera.app.data.model.stremio.IntroSegmentResponse
import com.lumera.app.data.remote.IntroDbService
import com.lumera.app.data.remote.StremioServerApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import java.util.concurrent.ConcurrentHashMap
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class IntroRepository @Inject constructor(
    private val introDbApi: IntroDbService,
    private val stremioServerApi: StremioServerApi
) {
    private val cache = ConcurrentHashMap<String, IntroDbSegmentsResponse>()
    private val serverCache = ConcurrentHashMap<String, IntroSegmentResponse>()

    suspend fun getSegments(
        imdbId: String,
        season: Int,
        episode: Int
    ): IntroDbSegmentsResponse? = withContext(Dispatchers.IO) {
        val cacheKey = "$imdbId:$season:$episode"
        cache[cacheKey]?.let { return@withContext it }

        try {
            val url = "$INTRODB_BASE_URL/segments?imdb_id=$imdbId&season=$season&episode=$episode"
            val response = withTimeout(TIMEOUT_MS) { introDbApi.getSegments(url) }
            cache[cacheKey] = response
            response
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Get intro segment from our self-hosted stremio server.
     * The server detects intros via ffmpeg silencedetect on the actual video file.
     * Returns null if the server doesn't have the info or detection is not complete.
     */
    suspend fun getSegmentsFromServer(
        baseUrl: String,
        infoHash: String,
        fileIdx: Int
    ): IntroSegmentResponse? = withContext(Dispatchers.IO) {
        val cacheKey = "$infoHash:$fileIdx"
        serverCache[cacheKey]?.let { return@withContext it }

        try {
            val statusUrl = "$baseUrl/intro/$infoHash/$fileIdx/status"
            val response = withTimeout(TIMEOUT_MS) { stremioServerApi.getIntroStatus(statusUrl) }
            if (response.introEnd != null && response.cached == true) {
                serverCache[cacheKey] = response
                response
            } else {
                // Detection not complete or not available
                null
            }
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Start intro detection on our stremio server (fire-and-forget).
     * The server will probe the video file with ffmpeg silencedetect in the background.
     */
    suspend fun startIntroDetection(
        baseUrl: String,
        infoHash: String,
        fileIdx: Int
    ): Unit = withContext(Dispatchers.IO) {
        try {
            val detectUrl = "$baseUrl/intro/$infoHash/$fileIdx"
            stremioServerApi.startIntroDetection(detectUrl)
        } catch (_: Exception) {
            // Ignore errors — detection is best-effort
        }
    }

    fun clearCache() {
        cache.clear()
        serverCache.clear()
    }

    companion object {
        private const val INTRODB_BASE_URL = "https://api.introdb.app"
        private const val TIMEOUT_MS = 5_000L
    }
}
