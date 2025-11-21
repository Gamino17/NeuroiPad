import { Controller, Get, Post, Param, Body, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { SamplesService } from './samples.service';

@ApiTags('samples')
@Controller('sessions/:sessionId/samples')
export class SamplesController {
  constructor(private samplesService: SamplesService) {}

  @Post()
  create(@Param('sessionId') sessionId: string, @Body() body: { samples: any[] }) {
    const samplesWithSession = body.samples.map(sample => ({
      ...sample,
      sessionId,
    }));
    return this.samplesService.createMany(samplesWithSession);
  }

  @Get()
  findAll(
    @Param('sessionId') sessionId: string,
    @Query('limit') limit?: number,
  ) {
    return this.samplesService.findBySessionId(sessionId, limit);
  }
}




