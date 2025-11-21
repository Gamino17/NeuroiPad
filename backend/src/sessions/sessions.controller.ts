import { Controller, Get, Post, Put, Param, Body } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { SessionsService } from './sessions.service';

@ApiTags('sessions')
@Controller('sessions')
export class SessionsController {
  constructor(private sessionsService: SessionsService) {}

  @Post()
  create(@Body() data: any) {
    return this.sessionsService.create(data);
  }

  @Get()
  findAll(@Body('userId') userId: string) {
    return this.sessionsService.findByUserId(userId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.sessionsService.findById(id);
  }

  @Put(':id/finish')
  finish(@Param('id') id: string, @Body() body: any) {
    return this.sessionsService.finish(id, body.summary);
  }

  @Put(':id/abort')
  abort(@Param('id') id: string) {
    return this.sessionsService.abort(id);
  }
}




