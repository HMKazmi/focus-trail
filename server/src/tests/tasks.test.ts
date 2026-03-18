/// <reference types="vitest/globals" />
import request from 'supertest';
import app from '../app';

async function registerAndLogin(email: string) {
  await request(app).post('/api/auth/register').send({ email, password: 'password123' });
  const res = await request(app).post('/api/auth/login').send({ email, password: 'password123' });
  return res.body.data.accessToken as string;
}

describe('Tasks API', () => {
  let token: string;

  beforeEach(async () => {
    token = await registerAndLogin('tasks@example.com');
  });

  it('POST /api/tasks - creates a task', async () => {
    const res = await request(app)
      .post('/api/tasks')
      .set('Authorization', `Bearer ${token}`)
      .send({ title: 'Buy groceries', status: 'todo' });

    expect(res.status).toBe(201);
    expect(res.body.data.task.title).toBe('Buy groceries');
    expect(res.body.data.task.status).toBe('todo');
  });

  it('GET /api/tasks - lists only current user tasks', async () => {
    await request(app)
      .post('/api/tasks')
      .set('Authorization', `Bearer ${token}`)
      .send({ title: 'Task A' });

    // Another user
    const otherToken = await registerAndLogin('other@example.com');
    await request(app)
      .post('/api/tasks')
      .set('Authorization', `Bearer ${otherToken}`)
      .send({ title: 'Other task' });

    const res = await request(app)
      .get('/api/tasks')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data.tasks).toHaveLength(1);
    expect(res.body.data.tasks[0].title).toBe('Task A');
  });

  it('PATCH /api/tasks/:id - partial update', async () => {
    const create = await request(app)
      .post('/api/tasks')
      .set('Authorization', `Bearer ${token}`)
      .send({ title: 'Old title' });

    const id = create.body.data.task._id;

    const res = await request(app)
      .patch(`/api/tasks/${id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'done' });

    expect(res.status).toBe(200);
    expect(res.body.data.task.status).toBe('done');
    expect(res.body.data.task.title).toBe('Old title');
  });

  it('DELETE /api/tasks/:id - deletes a task', async () => {
    const create = await request(app)
      .post('/api/tasks')
      .set('Authorization', `Bearer ${token}`)
      .send({ title: 'To delete' });

    const id = create.body.data.task._id;

    const del = await request(app)
      .delete(`/api/tasks/${id}`)
      .set('Authorization', `Bearer ${token}`);

    expect(del.status).toBe(204);

    const get = await request(app)
      .get(`/api/tasks/${id}`)
      .set('Authorization', `Bearer ${token}`);

    expect(get.status).toBe(404);
  });

  it('GET /api/tasks - returns 401 without token', async () => {
    const res = await request(app).get('/api/tasks');
    expect(res.status).toBe(401);
  });
});
