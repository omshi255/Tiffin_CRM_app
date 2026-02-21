import { Router } from "express";

const router = Router();

router.post("/test-body", (req, res) => {
  res.json({ body: req.body });
});

export default router;
