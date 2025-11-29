package com.mollysou.services;

import com.mollysou.dto.EventDTO;
import com.mollysou.entities.Event;
import com.mollysou.repositories.EventRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class EventService {

    @Autowired
    private EventRepository eventRepository;

    public List<EventDTO> getAllEvents() {
        return eventRepository.findByOrderByDateAsc().stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    public List<EventDTO> getPopularEvents() {
        // Return events with highest ratings or most recent
        return eventRepository.findByOrderByDateAsc().stream()
                .limit(4) // Top 4 events
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    public EventDTO getEventById(Long id) {
        return eventRepository.findById(id)
                .map(this::convertToDTO)
                .orElse(null);
    }

    private EventDTO convertToDTO(Event event) {
        EventDTO dto = new EventDTO();
        dto.setId(event.getId());
        dto.setTitre(event.getTitre());
        dto.setDescription(event.getDescription());
        dto.setDate(event.getDate());
        dto.setPrix(event.getPrix());
        dto.setImage(event.getImage());
        dto.setLieu(event.getLieu());
        dto.setRating(event.getRating());
        dto.setType(event.getType());
        return dto;
    }
}
