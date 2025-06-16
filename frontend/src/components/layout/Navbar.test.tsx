import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import Navbar from './Navbar';

describe('Navbar', () => {
  it('renders the navbar with logo', () => {
    render(
      <BrowserRouter>
        <Navbar collapsed={false} onToggle={() => {}} />
      </BrowserRouter>,
    );

    const logo = screen.getByText(/抖音数据分析平台/i);
    expect(logo).toBeInTheDocument();
  });

  it('renders theme toggle button', () => {
    render(
      <BrowserRouter>
        <Navbar collapsed={false} onToggle={() => {}} />
      </BrowserRouter>,
    );

    const themeButton = screen.getByRole('button', { name: /moon|sun/i });
    expect(themeButton).toBeInTheDocument();
  });
});
