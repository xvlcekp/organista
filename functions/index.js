// This method removes musicSheet physical file from storage when it is removed in Firebase Database

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const bucket = admin.storage().bucket(); // Initialize Firebase Storage bucket

exports.deleteStorageFilesOnDocDelete = functions.firestore
.onDocumentDeleted(
    "musicSheets/{documentId}", 
    async (event) => {
        const snap = event.data;
        const deletedData = snap.data();
        console.log(`Event triggered ${deletedData}`);
        const filePath = deletedData && deletedData.original_file_storage_id; // Handle potential undefined values

        if (!filePath) {
            console.log("No fileId found, skipping file deletion.");
            return null;
        }

        try {
            const file = bucket.file(filePath);
            console.log(`File reference created for: ${filePath}`);
            
            // Check if the file exists
            const [exists] = await file.exists();
            if (!exists) {
                console.log("File does not exist.");
                return null;
            }

            // Delete all matching files
            await file.delete();

            console.log(`Deleted file with path: ${filePath}`);
        } catch (error) {
            console.error("Error deleting files:", error);
        }

        return null;
  });
