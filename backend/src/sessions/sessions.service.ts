import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Session, SessionDocument } from './schemas/session.schema';

@Injectable()
export class SessionsService {
  constructor(
    @InjectModel(Session.name) private sessionModel: Model<SessionDocument>,
  ) {}

  async create(data: any): Promise<Session> {
    const session = new this.sessionModel({
      ...data,
      startedAt: new Date(),
      status: 'active',
    });
    return session.save();
  }

  async findById(id: string): Promise<Session> {
    return this.sessionModel.findById(id);
  }

  async findByUserId(userId: string): Promise<Session[]> {
    return this.sessionModel.find({ userId }).sort({ startedAt: -1 });
  }

  async finish(id: string, summary?: any): Promise<Session> {
    return this.sessionModel.findByIdAndUpdate(
      id,
      {
        endedAt: new Date(),
        status: 'completed',
        summary,
      },
      { new: true },
    );
  }

  async abort(id: string): Promise<Session> {
    return this.sessionModel.findByIdAndUpdate(
      id,
      {
        endedAt: new Date(),
        status: 'aborted',
      },
      { new: true },
    );
  }
}




