const router = require('express').Router();
const { prisma } = require('../prisma');

const tzTodayFilter = `
  (created_at AT TIME ZONE 'Europe/Istanbul')::date = (now() AT TIME ZONE 'Europe/Istanbul')::date
`;

router.get('/today', async (req, res) => {
  const userId = req.user.id;

  // Water
  const waterGoal = await prisma.waterGoal.findFirst({ where: { userId }, orderBy: { createdAt: 'desc' } });
  const waterLogs = await prisma.$queryRawUnsafe(
    `SELECT COALESCE(SUM(glasses),0)::int AS total FROM "WaterLog" WHERE "userId"=$1 AND ${tzTodayFilter.replaceAll('created_at','"createdAt"')}`,
    userId
  );
  const waterCount = Number(waterLogs[0]?.total || 0);
  const wGoal = waterGoal?.goal ?? 8;
  const wPercent = wGoal ? Math.min(waterCount / wGoal, 1) : 0;

  // Steps
  const stepGoal = await prisma.stepGoal.findFirst({ where: { userId }, orderBy: { createdAt: 'desc' } });
  const stepLogs = await prisma.$queryRawUnsafe(
    `SELECT COALESCE(SUM(steps),0)::int AS total FROM "StepLog" WHERE "userId"=$1 AND ${tzTodayFilter.replaceAll('created_at','"createdAt"')}`,
    userId
  );
  const steps = Number(stepLogs[0]?.total || 0);
  const sGoal = stepGoal?.goal ?? 10000;
  const sPercent = sGoal ? Math.min(steps / sGoal, 1) : 0;
  const distanceKm = steps * 0.0007;
  const calories = Math.round(steps * 0.04);

  // Exercise
  const exRows = await prisma.$queryRawUnsafe(
    `SELECT COALESCE(SUM(minutes),0)::int AS mins, COALESCE(SUM(calories),0)::int AS kcals, COUNT(*)::int AS cnt
     FROM "ExerciseLog"
     WHERE "userId"=$1 AND ${tzTodayFilter.replaceAll('created_at','"createdAt"')}`,
    userId
  );
  const ex = exRows[0] || { mins: 0, kcals: 0, cnt: 0 };
  const exPercent = Math.min(ex.mins / 60, 1); // örnek: 60dk hedef varsaydık

  const overall = Math.min((wPercent + sPercent + exPercent) / 3, 1);

  return res.json({
    water: { count: waterCount, goal: wGoal, percent: wPercent },
    steps: { count: steps, goal: sGoal, percent: sPercent, distanceKm, calories },
    exercise: { count: ex.cnt, minutes: ex.mins, calories: ex.kcals, percent: exPercent },
    overall
  });
});

module.exports = router;
