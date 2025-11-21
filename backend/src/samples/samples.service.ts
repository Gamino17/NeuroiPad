import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Sample, SampleDocument } from './schemas/sample.schema';

@Injectable()
export class SamplesService {
  constructor(
    @InjectModel(Sample.name) private sampleModel: Model<SampleDocument>,
  ) {}

  async createMany(samples: any[]): Promise<any> {
    return this.sampleModel.insertMany(samples);
  }

  async findBySessionId(sessionId: string, limit?: number): Promise<Sample[]> {
    const query = this.sampleModel.find({ sessionId }).sort({ timestamp: 1 });
    if (limit) {
      query.limit(limit);
    }
    return query.exec();
  }
}

