import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type SessionDocument = Session & Document;

@Schema({ timestamps: true })
export class Session {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ required: true })
  type: string;

  @Prop({ required: true })
  device: string;

  @Prop({ required: true })
  startedAt: Date;

  @Prop()
  endedAt: Date;

  @Prop({ default: 'active', enum: ['active', 'completed', 'aborted'] })
  status: string;

  @Prop({ type: Object })
  metadata: Record<string, any>;

  @Prop({ type: Object })
  summary: Record<string, any>;
}

export const SessionSchema = SchemaFactory.createForClass(Session);

