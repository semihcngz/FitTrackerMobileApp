const router = require('express').Router();
const { prisma } = require('../prisma');

const tzToday = `( "createdAt" AT TIME ZONE 'Europe/Istanbul')::date = (now() AT TIME ZONE 'Europe/Istanbul')::date`;

router.get('/today', async (req, res) => {
  const uid = req.user.id;
  const goalRow = await prisma.stepGoal.findFirst({ where: { userId: uid }, orderBy: { createdAt: 'desc' } });
  const rows = await prisma.$queryRawUnsafe(
    `SELECT COALESCE(SUM(steps),0)::int AS total FROM "StepLog" WHERE "userId"=$1 AND ${tzToday}`,
    uid
  );
  const count = Number(rows[0]?.total || 0);
  const distanceKm = count * 0.0007;
  const calories = Math.round(count * 0.04);
  return res.json({ count, goal: goalRow?.goal ?? 10000, distanceKm, calories });
});

router.post('/add', async (req, res) => {
  const uid = req.user.id;
  const { steps } = req.body || {};
  if (!Number.isInteger(steps)) return res.status(400).json({ message: 'steps must be integer' });
  await prisma.stepLog.create({ data: { userId: uid, steps } });
  return res.json({ message: 'ok' });
});

router.put('/goal', async (req, res) => {
  const uid = req.user.id;
  const { goal } = req.body || {};
  if (!Number.isInteger(goal) || goal <= 0) return res.status(400).json({ message: 'invalid goal' });
  await prisma.stepGoal.create({ data: { userId: uid, goal } });
  return res.json({ message: 'ok' });
});

module.exports = router;
