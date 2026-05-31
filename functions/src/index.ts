import { initializeApp } from "firebase-admin/app";

// Admin SDK 初期化（全関数で 1 度だけ）
initializeApp();

export { awardPointsOnRating } from "./awardPoints";
export { promoteOnApproval } from "./promoteReviewer";
