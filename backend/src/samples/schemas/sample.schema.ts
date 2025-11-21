import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type SampleDocument = Sample & Document;

@Schema({ timestamps: true })
export class Sample {
  @Prop({ type: Types.ObjectId, ref: 'Session', required: true })
  sessionId: Types.ObjectId;

  @Prop({ required: true })
  timestamp: Date;

  @Prop({ type: [Number], required: true })
  eegChannels: number[];

  @Prop({ type: Object })
  accelerometer: Record<string, any>;

  @Prop({ type: Object })
  gyroscope: Record<string, any>;

  @Prop({ type: [Number] })
  signalQuality: number[];
}

export const SampleSchema = SchemaFactory.createForClass(Sample);
SampleSchema.index({ sessionId: 1, timestamp: 1 });




