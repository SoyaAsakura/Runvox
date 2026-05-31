import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { calculatePoints } from "./pointCalculator";

const REGION = "asia-northeast1";

/**
 * 回答に評価が付いたら、回答者へポイントを Admin 権限で付与する。
 *
 * - トリガ: `answers/{answerId}` の更新で `rating` が **null → 値** に変わった初回のみ
 * - 付与内容: `pointTransactions` 作成 + `userPoints/{answererId}` を加算
 * - 冪等性: `answer.pointAwarded == true` なら二重付与しない。付与時にこのフラグを立てる。
 *   フラグ更新で再トリガされても「rating は既に非 null」なので即 return する（再帰防止）。
 *
 * これによりポイントの真実の源はサーバ（Admin）に限定され、クライアントは
 * `rating` を書くだけになる（残高の改ざん不可）。
 */
export const awardPointsOnRating = onDocumentUpdated(
  { document: "answers/{answerId}", region: REGION, maxInstances: 10 },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const ratingBefore = before.rating ?? null;
    const ratingAfter = after.rating ?? null;

    // null → 値 の初回付与だけを対象にする（再トリガ・再評価は無視）
    if (ratingBefore !== null || ratingAfter === null) return;
    if (typeof ratingAfter !== "number" || ratingAfter < 1 || ratingAfter > 5) return;
    if (after.pointAwarded === true) return;

    const answerId = event.params.answerId;
    const answererId = after.answererId as string | undefined;
    const questionId = after.questionId as string | undefined;
    const rank = (after.answererRank as string | undefined) ?? "B";
    if (!answererId) {
      logger.warn(`answer ${answerId} に answererId が無いため付与スキップ`);
      return;
    }

    const { basePoints, multiplier, pointsAwarded } = calculatePoints(ratingAfter, rank);
    const db = getFirestore();

    // 表示用に questionTitle を denormalize（トランザクション外で読んで良い）
    let questionTitle = "";
    let questionExists = false;
    if (questionId) {
      const qSnap = await db.collection("questions").doc(questionId).get();
      questionExists = qSnap.exists;
      questionTitle = (qSnap.data()?.title as string) ?? "";
    }

    const answerRef = db.collection("answers").doc(answerId);
    const txRef = db.collection("pointTransactions").doc();
    const userPointsRef = db.collection("userPoints").doc(answererId);

    await db.runTransaction(async (tx) => {
      // トランザクション内で冪等性を再確認（同時実行に強くする）
      const snap = await tx.get(answerRef);
      if (snap.data()?.pointAwarded === true) return;

      tx.set(txRef, {
        userId: answererId,
        answerId,
        questionTitle,
        stars: ratingAfter,
        rank,
        basePoints,
        multiplier,
        pointsAwarded,
        createdAt: Timestamp.now(),
      });
      tx.set(
        userPointsRef,
        {
          balance: FieldValue.increment(pointsAwarded),
          lifetimeEarned: FieldValue.increment(pointsAwarded),
          thisMonthEarned: FieldValue.increment(pointsAwarded),
        },
        { merge: true },
      );
      tx.update(answerRef, { pointAwarded: true });

      // 質問カード表示用の latestRating を denormalize（クライアントは書かない）
      if (questionId && questionExists) {
        tx.update(db.collection("questions").doc(questionId), { latestRating: ratingAfter });
      }
    });

    logger.info(
      `awarded ${pointsAwarded}pt to ${answererId} (answer=${answerId}, stars=${ratingAfter}, rank=${rank})`,
    );
  },
);
