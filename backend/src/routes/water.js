const router = require('express').Router();
const { prisma } = require('../prisma');

const tzToday = `( "createdAt" AT TIME ZONE 'Europe/Istanbul')::date = (now() AT TIME ZONE 'Europe/Istanbul')::date`;

router.get('/today', async (req, res) => {
  const uid = req.user.id;
  const goalRow = await prisma.waterGoal.findFirst({ where: { userId: uid }, orderBy: { createdAt: 'desc' } });
  const rows = await prisma.$queryRawUnsafe(
    `SELECT COALESCE(SUM(glasses),0)::int AS total FROM "WaterLog" WHERE "userId"=$1 AND ${tzToday}`,
    uid
  );
  return res.json({ count: Number(rows[0]?.total || 0), goal: goalRow?.goal ?? 8 });
});

router.post('/add', async (req, res) => {
  const uid = req.user.id;
  const { glasses } = req.body || {};
  if (typeof glasses !== 'number') return res.status(400).json({ message: 'glasses must be number' });
  await prisma.waterLog.create({ data: { userId: uid, glasses } });
  return res.json({ message: 'ok' });
});

router.put('/goal', async (req, res) => {
  const uid = req.user.id;
  const { goal } = req.body || {};
  if (!Number.isInteger(goal) || goal <= 0) return res.status(400).json({ message: 'invalid goal' });
  await prisma.waterGoal.create({ data: { userId: uid, goal } });
  return res.json({ message: 'ok' });
});

module.exports = router;
