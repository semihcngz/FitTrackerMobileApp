const router = require('express').Router();
const { prisma } = require('../prisma');

const tzToday = `( "createdAt" AT TIME ZONE 'Europe/Istanbul')::date = (now() AT TIME ZONE 'Europe/Istanbul')::date`;

router.get('/today', async (req, res) => {
  const uid = req.user.id;
  const rows = await prisma.$queryRawUnsafe(
    `SELECT COALESCE(SUM(minutes),0)::int AS mins, COALESCE(SUM(calories),0)::int AS kcals, COUNT(*)::int AS cnt
     FROM "ExerciseLog" WHERE "userId"=$1 AND ${tzToday}`,
    uid
  );
  const list = await prisma.$queryRawUnsafe(
    `SELECT id, type, activity, minutes, calories, "createdAt"
     FROM "ExerciseLog" WHERE "userId"=$1 AND ${tzToday} ORDER BY "createdAt" DESC`,
    uid
  );
  const r = rows[0] || { mins: 0, kcals: 0, cnt: 0 };
  return res.json({ minutes: r.mins, calories: r.kcals, count: r.cnt, list });
});

router.post('/add', async (req, res) => {
  const uid = req.user.id;
  const { type, activity, minutes, calories } = req.body || {};
  if (!type || !activity || !Number.isInteger(minutes) || !Number.isInteger(calories))
    return res.status(400).json({ message: 'invalid body' });
  await prisma.exerciseLog.create({ data: { userId: uid, type, activity, minutes, calories } });
  return res.json({ message: 'ok' });
});

module.exports = router;
