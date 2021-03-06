#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import time
import os
import threading


class MetricsAggregator(threading.Thread):

  def __init__(self, path):
    super(MetricsAggregator, self).__init__()
    self._stop_event = threading.Event()
    self.__store = dict()
    self.__path = path
    self.__last_value = None

  def stop(self) -> None:
    self._stop_event.set()
    self.join()
    time.sleep(0.5)
    self.__process_change()

  def __process_change(self) -> None:
    if not os.path.isfile(self.__path):
      return
    try:
      with open(self.__path, mode='r', encoding='ascii') as fd:
        data = json.load(fd)
        (i, e, m) = data['messageIngress'], data['messageEgress'], data['memoryAllocated']
        del data
        value = '{}/{}/{}'.format(i, e, m)
        if value != self.__last_value:
          self.__store[str(int(time.time()*1000))] = value
          self.__last_value = value
    except:
      pass

  def get_metrics(self) -> dict:
    return self.__store

  def run(self) -> None:
    self.__process_change()
    while not self._stop_event.is_set():
      self.__process_change()
      time.sleep(1)
    self.__process_change()
