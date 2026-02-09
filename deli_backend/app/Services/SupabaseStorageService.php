<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class SupabaseStorageService
{
    protected $url;
    protected $key;
    protected $bucket;

    public function __construct()
    {
        $this->url = env('SUPABASE_URL');
        // Use service_role key if available (bypasses RLS), otherwise use anon key
        $this->key = env('SUPABASE_SERVICE_ROLE_KEY') ?: env('SUPABASE_KEY');
        $this->bucket = env('SUPABASE_BUCKET', 'package-images');
        
        // Validate URL format
        if ($this->url && !filter_var($this->url, FILTER_VALIDATE_URL)) {
            Log::warning('Invalid SUPABASE_URL format', ['url' => $this->url]);
            $this->url = null;
        }
        
        // Remove trailing slash if present
        if ($this->url) {
            $this->url = rtrim($this->url, '/');
        }
    }

    /**
     * Upload image to Supabase Storage
     *
     * @param string $path File path (e.g., 'package_images/filename.jpg')
     * @param string $content Image content (binary data)
     * @param string|null $errorMessage Reference to store error message
     * @return string|null Public URL or null on failure
     */
    public function upload(string $path, string $content, ?string &$errorMessage = null): ?string
    {
        if (!$this->url || !$this->key) {
            $errorMessage = 'Supabase not configured. Image upload skipped. Package saved without image.';
            Log::warning('Supabase credentials not configured - image upload skipped', [
                'url_set' => !empty($this->url),
                'key_set' => !empty($this->key),
                'hint' => 'Set SUPABASE_URL and SUPABASE_KEY in Render environment variables to enable image uploads',
            ]);
            return null;
        }

        try {
            $uploadUrl = "{$this->url}/storage/v1/object/{$this->bucket}/{$path}";
            
            Log::info('Attempting Supabase upload', [
                'url' => $uploadUrl,
                'bucket' => $this->bucket,
                'path' => $path,
                'content_size' => strlen($content),
            ]);
            
            // Supabase Storage API requires raw binary data in the body
            // Use withBody() to send raw binary instead of JSON/form-data
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $this->key,
                'Content-Type' => 'image/jpeg',
                'x-upsert' => 'true', // Overwrite if exists
            ])->withBody($content, 'image/jpeg')->post($uploadUrl);
            
            // If POST fails with 405, try PUT
            if ($response->status() === 405) {
                Log::info('POST not allowed, trying PUT', ['url' => $uploadUrl]);
                $response = Http::withHeaders([
                    'Authorization' => 'Bearer ' . $this->key,
                    'Content-Type' => 'image/jpeg',
                    'x-upsert' => 'true',
                ])->withBody($content, 'image/jpeg')->put($uploadUrl);
            }

            if ($response->successful()) {
                // Generate public URL - URL encode the path to handle special characters
                // Split path into parts and encode each part separately to preserve slashes
                $pathParts = explode('/', $path);
                $encodedPathParts = array_map('rawurlencode', $pathParts);
                $encodedPath = implode('/', $encodedPathParts);
                
                $publicUrl = "{$this->url}/storage/v1/object/public/{$this->bucket}/{$encodedPath}";
                Log::info('Image uploaded to Supabase successfully', [
                    'path' => $path,
                    'encoded_path' => $encodedPath,
                    'url' => $publicUrl,
                ]);
                return $publicUrl;
            } else {
                $errorBody = $response->body();
                
                // Try to decode JSON, but handle non-JSON responses (binary data, HTML, etc.)
                $errorJson = null;
                $supabaseError = null;
                
                if (!empty($errorBody)) {
                    // Check if response is valid JSON
                    $errorJson = json_decode($errorBody, true);
                    
                    if (json_last_error() === JSON_ERROR_NONE && is_array($errorJson)) {
                        // Valid JSON response
                        $supabaseError = $errorJson['message'] ?? $errorJson['error'] ?? $errorJson['error_description'] ?? 'Unknown error';
                    } else {
                        // Not JSON - might be binary data, HTML, or plain text
                        // Try to extract readable text (first 200 chars)
                        $readableText = mb_convert_encoding(substr($errorBody, 0, 200), 'UTF-8', 'UTF-8');
                        // Remove non-printable characters
                        $readableText = preg_replace('/[\x00-\x1F\x7F]/', '', $readableText);
                        $supabaseError = !empty($readableText) ? $readableText : 'Non-JSON response received';
                    }
                } else {
                    $supabaseError = 'Empty response from Supabase';
                }
                
                // Sanitize error message to ensure it's valid UTF-8 and can be JSON encoded
                $sanitizedError = mb_convert_encoding($supabaseError, 'UTF-8', 'UTF-8');
                $sanitizedError = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/', '', $sanitizedError);
                $sanitizedError = substr($sanitizedError, 0, 200); // Limit length
                $errorMessage = "HTTP {$response->status()}: " . $sanitizedError;
                
                Log::error('Supabase upload failed', [
                    'path' => $path,
                    'bucket' => $this->bucket,
                    'status' => $response->status(),
                    'status_text' => $response->reason(),
                    'error_message' => $sanitizedError,
                    'upload_url' => $uploadUrl,
                ]);
                return null;
            }
        } catch (\Exception $e) {
            // Check if it's a DNS resolution or connection error
            $exceptionMsg = mb_convert_encoding($e->getMessage(), 'UTF-8', 'UTF-8');
            $exceptionMsg = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/', '', $exceptionMsg);
            $exceptionMsg = substr($exceptionMsg, 0, 200);
            
            // Check if it's a DNS resolution error
            if (strpos($exceptionMsg, 'Could not resolve host') !== false || 
                strpos($exceptionMsg, 'getaddrinfo') !== false ||
                strpos($exceptionMsg, 'cURL error 6') !== false) {
                $errorMessage = 'DNS Error: Cannot resolve Supabase hostname. Please check SUPABASE_URL environment variable in Render.';
                
                Log::error('Supabase upload DNS error', [
                    'path' => $path,
                    'bucket' => $this->bucket,
                    'url' => $this->url,
                    'error' => $exceptionMsg,
                    'error_type' => 'DNS Resolution',
                    'hint' => 'Check SUPABASE_URL in Render environment variables',
                ]);
            } else {
                $errorMessage = 'Exception: ' . $exceptionMsg;
                
                Log::error('Supabase upload exception', [
                    'path' => $path,
                    'bucket' => $this->bucket,
                    'url' => $this->url,
                    'error' => $exceptionMsg,
                ]);
            }
            
            return null;
        }
    }

    /**
     * Delete image from Supabase Storage
     *
     * @param string $path File path
     * @return bool Success status
     */
    public function delete(string $path): bool
    {
        if (!$this->url || !$this->key) {
            Log::error('Supabase credentials not configured');
            return false;
        }

        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $this->key,
            ])->delete(
                "{$this->url}/storage/v1/object/{$this->bucket}/{$path}"
            );

            if ($response->successful()) {
                Log::info('Image deleted from Supabase', ['path' => $path]);
                return true;
            } else {
                Log::warning('Supabase delete failed', [
                    'path' => $path,
                    'status' => $response->status(),
                    'response' => $response->body(),
                ]);
                return false;
            }
        } catch (\Exception $e) {
            Log::error('Supabase delete exception', [
                'path' => $path,
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    /**
     * Extract path from Supabase URL
     *
     * @param string $url Full Supabase URL
     * @return string|null Path or null if invalid
     */
    public function extractPathFromUrl(string $url): ?string
    {
        // Extract path from URL like: https://xxx.supabase.co/storage/v1/object/public/bucket/path
        // Or: https://xxx.supabase.co/storage/v1/object/public/package-images/package_images/filename.jpg
        $pattern = '/\/storage\/v1\/object\/public\/' . preg_quote($this->bucket, '/') . '\/(.+)$/';
        if (preg_match($pattern, $url, $matches)) {
            return urldecode($matches[1]); // Decode URL-encoded characters
        }
        
        // Try alternative pattern without bucket name (if bucket is in path)
        $pattern2 = '/\/storage\/v1\/object\/public\/[^\/]+\/(.+)$/';
        if (preg_match($pattern2, $url, $matches)) {
            return urldecode($matches[1]);
        }
        
        return null;
    }
}

