import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { getFirestore } from "firebase-admin/firestore";

const REGION = "asia-northeast1";

/**
 * 回答者審査が「承認」されたら、対象ユーザーを回答者ロールへ昇格させる。
 *
 * - トリガ: `reviewerApplications/{id}` の status が **approved 以外 → approved** に変化
 * - 動作: `users/{userId}` の `role` を `answerer`、`rank` を `assignedRank` に更新（Admin 権限）
 *
 * role / rank の変更は本関数（Admin）に限定され、クライアントからの自己昇格は
 * セキュリティルールで禁止する（別 PR）。
 */
export const promoteOnApproval = onDocumentUpdated(
  { document: "reviewerApplications/{applicationId}", region: REGION, maxInstances: 10 },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // approved への遷移時のみ
    if (before.status === "approved" || after.status !== "approved") return;

    const userId = after.userId as string | undefined;
    const assignedRank = (after.assignedRank as string | undefined) ?? "B";
    if (!userId) {
      logger.warn(`application ${event.params.applicationId} に userId が無いため昇格スキップ`);
      return;
    }

    await getFirestore()
      .collection("users")
      .doc(userId)
      .set({ role: "answerer", rank: assignedRank }, { merge: true });

    logger.info(`promoted ${userId} to answerer (rank=${assignedRank})`);
  },
);
