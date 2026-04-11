// Cloudinary Configuration
const CLOUD_NAME = "ddflgi3w3";
const API_KEY = "416471628692265";
const API_SECRET = "wIIc34TUmfvjfVpk2I5bd9tX1gA";

/**
 * Uploads an image File to Cloudinary.
 * @param {File} file - The file to upload.
 * @param {string} folderName - The target folder name in Cloudinary.
 * @returns {Promise<string|null>} The secure URL of the uploaded image or null if failed.
 */
export const uploadImageToCloudinary = async (file, folderName = "uploads") => {
  if (!file) return null;

  try {
    const timestamp = Math.floor(Date.now() / 1000).toString();
    
    // Create signature using Web Crypto API or simple fallback logic since it's client side
    // WARNING: In production, signature generation should happen on a secure backend.
    // However, to mimic the Flutter behavior securely over HTTPS:
    const strToSign = `folder=${folderName}&timestamp=${timestamp}${API_SECRET}`;
    
    const encoder = new TextEncoder();
    const data = encoder.encode(strToSign);
    const hashBuffer = await crypto.subtle.digest('SHA-1', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const signature = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

    const url = `https://api.cloudinary.com/v1_1/${CLOUD_NAME}/image/upload`;
    
    const formData = new FormData();
    formData.append("file", file);
    formData.append("api_key", API_KEY);
    formData.append("timestamp", timestamp);
    formData.append("signature", signature);
    formData.append("folder", folderName);

    const response = await fetch(url, {
      method: 'POST',
      body: formData,
    });

    if (response.ok) {
      const result = await response.json();
      return result.secure_url; // the URL to display
    } else {
      const err = await response.text();
      console.error("Cloudinary Upload Failed", response.status, err);
      return null;
    }
  } catch (err) {
    console.error("Error uploading to Cloudinary:", err);
    return null;
  }
};
